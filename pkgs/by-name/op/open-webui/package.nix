{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  python312,
  nixosTests,
  fetchurl,
}:
let
  pname = "open-webui";
  version = "0.6.7";

  src = fetchFromGitHub {
    owner = "open-webui";
    repo = "open-webui";
    tag = "v${version}";
    hash = "sha256-4V0WhiVhjxYtbwDt+83AfkjJtQFew2P6i1sLtRL13lg=";
  };

  frontend = buildNpmPackage rec {
    inherit pname version src;

    # the backend for run-on-client-browser python execution
    # must match lock file in open-webui
    # TODO: should we automate this?
    # TODO: with JQ? "jq -r '.packages["node_modules/pyodide"].version' package-lock.json"
    pyodideVersion = "0.27.3";
    pyodide = fetchurl {
      hash = "sha256-SeK3RKqqxxLLf9DN5xXuPw6ZPblE6OX9VRXMzdrmTV4=";
      url = "https://github.com/pyodide/pyodide/releases/download/${pyodideVersion}/pyodide-${pyodideVersion}.tar.bz2";
    };

    npmDepsHash = "sha256-kOqfYAMkpiT2d79fpH1ON5FQAuV1i3/PL9waQq/YR58=";

    # Disabling `pyodide:fetch` as it downloads packages during `buildPhase`
    # Until this is solved, running python packages from the browser will not work.
    postPatch = ''
      substituteInPlace package.json \
        --replace-fail "npm run pyodide:fetch && vite build" "vite build"
    '';

    env.CYPRESS_INSTALL_BINARY = "0"; # disallow cypress from downloading binaries in sandbox
    env.ONNXRUNTIME_NODE_INSTALL_CUDA = "skip";
    env.NODE_OPTIONS = "--max-old-space-size=8192";

    preBuild = ''
      tar xf ${pyodide} -C static/
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share
      cp -a build $out/share/open-webui

      runHook postInstall
    '';
  };
in
python312.pkgs.buildPythonApplication rec {
  inherit pname version src;
  pyproject = true;

  build-system = with python312.pkgs; [ hatchling ];

  # Not force-including the frontend build directory as frontend is managed by the `frontend` derivation above.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail ', build = "open_webui/frontend"' ""
  '';

  env.HATCH_BUILD_NO_HOOKS = true;

  pythonRelaxDeps = true;

  pythonRemoveDeps = [
    "docker"
    "pytest"
    "pytest-docker"
  ];

  dependencies =
    with python312.pkgs;
    [
      accelerate
      aiocache
      aiofiles
      aiohttp
      alembic
      anthropic
      apscheduler
      argon2-cffi
      asgiref
      async-timeout
      authlib
      azure-ai-documentintelligence
      azure-identity
      azure-storage-blob
      bcrypt
      beautifulsoup4
      black
      boto3
      chromadb
      colbert-ai
      docx2txt
      duckduckgo-search
      einops
      elasticsearch
      extract-msg
      fake-useragent
      fastapi
      faster-whisper
      firecrawl-py
      fpdf2
      ftfy
      gcp-storage-emulator
      google-api-python-client
      google-auth-httplib2
      google-auth-oauthlib
      google-cloud-storage
      google-generativeai
      googleapis-common-protos
      iso-639
      langchain
      langchain-community
      langdetect
      langfuse
      ldap3
      loguru
      markdown
      moto
      nltk
      onnxruntime
      openai
      opencv-python-headless
      openpyxl
      opensearch-py
      opentelemetry-api
      opentelemetry-sdk
      opentelemetry-exporter-otlp
      opentelemetry-instrumentation
      opentelemetry-instrumentation-fastapi
      opentelemetry-instrumentation-sqlalchemy
      opentelemetry-instrumentation-redis
      opentelemetry-instrumentation-requests
      opentelemetry-instrumentation-logging
      opentelemetry-instrumentation-httpx
      opentelemetry-instrumentation-aiohttp-client
      pandas
      passlib
      peewee
      peewee-migrate
      pgvector
      pillow
      pinecone-client
      playwright
      psutil
      psycopg2-binary
      pydub
      pyjwt
      pymdown-extensions
      pymilvus
      pymongo
      pymysql
      pypandoc
      pypdf
      python-dotenv
      python-jose
      python-multipart
      python-pptx
      python-socketio
      pytube
      pyxlsb
      qdrant-client
      rank-bm25
      rapidocr-onnxruntime
      redis
      requests
      restrictedpython
      sentence-transformers
      sentencepiece
      soundfile
      tencentcloud-sdk-python
      tiktoken
      transformers
      unstructured
      uvicorn
      validators
      xlrd
      youtube-transcript-api
    ]
    ++ moto.optional-dependencies.s3;

  pythonImportsCheck = [ "open_webui" ];

  makeWrapperArgs = [ "--set FRONTEND_BUILD_DIR ${frontend}/share/open-webui" ];

  passthru = {
    tests = {
      inherit (nixosTests) open-webui;
    };
    updateScript = ./update.sh;
    inherit frontend;
  };

  meta = {
    changelog = "https://github.com/open-webui/open-webui/blob/${src.tag}/CHANGELOG.md";
    description = "Comprehensive suite for LLMs with a user-friendly WebUI";
    homepage = "https://github.com/open-webui/open-webui";
    license = lib.licenses.mit;
    mainProgram = "open-webui";
    maintainers = with lib.maintainers; [
      drupol
      shivaraj-bh
    ];
  };
}

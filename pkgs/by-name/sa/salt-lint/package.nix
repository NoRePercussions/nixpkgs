{ lib, testers, python3Packages, fetchPypi, salt-lint }:

python3Packages.buildPythonApplication rec {
  pname = "salt-lint";
  version = "0.9.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-f3Tmguf9eHIqbTkeqO3J/HlRE+z9QGV9aAV9QE7nvo4=";
  };

  propagatedBuildInputs = with python3Packages; [
    pipBuildHook
    pathspec
    pyyaml
  ];

  pythonImportsCheck = [ "saltlint" ];

  passthru.tests = {
    version = testers.testVersion { package = salt-lint; };
  };

  meta = with lib; {
    description = "A command-line utility that checks for best practices in SaltStack.";
    homepage = "https://github.com/warpnet/salt-lint";
    license = licenses.mit;
    maintainers = with maintainers; [ norepercussions ];
    mainProgram = "salt-lint";
  };
}

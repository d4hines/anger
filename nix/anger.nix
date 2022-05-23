{ pkgs, stdenv, lib, ocamlPackages, static ? false, doCheck }:

with ocamlPackages;

let feather = buildDunePackage {
  pname = "feather";
  version = "0.3.0";
  src = builtins.fetchurl {
    url = "https://github.com/charlesetc/feather/archive/refs/tags/0.3.0.tar.gz";
    sha256 = "0mkycpkpq9jrlaf3zc367l6m88521zg0zpsd5g93c72azp7gj7zg";
  };
  propagatedBuildInputs = [ ppx_expect spawn ];
};
in
rec {
  service = buildDunePackage {
    pname = "anger";
    version = "0.0.1";

    src = lib.filterGitSource {
      src = ./..;
      dirs = [ "src" ];
      files = [ "dune-project" "anger.opam" ];
    };

    # Static builds support, note that you need a static profile in your dune file
    buildPhase = ''
      echo "running ${if static then "static" else "release"} build"
      dune build src/anger.exe --display=short --profile=${if static then "static" else "release"}
    '';
    installPhase = ''
      mkdir -p $out/bin
      mv _build/default/src/anger.exe $out/bin/anger
    '';

    checkInputs = [
    ];

    propagatedBuildInputs = [
      cmdliner
      feather
    ];

    inherit doCheck;

    meta = {
      description = "CLI for automating stacked PR's in Git";
    };
  };
}

{ pkgs, stdenv, lib, ocamlPackages, static ? false, doCheck }:

with ocamlPackages;
rec {
  service = buildDunePackage {
    pname = "service";
    version = "0.1.0";

    src = lib.filterGitSource {
      src = ./..;
      dirs = [ "src" ];
      files = [ "dune-project" "service.opam" ];
    };

    # Static builds support, note that you need a static profile in your dune file
    buildPhase = ''
      echo "running ${if static then "static" else "release"} build"
      dune build src/bin/service.exe --display=short --profile=${if static then "static" else "release"}
    '';
    installPhase = ''
      mkdir -p $out/bin
      mv _build/default/bin/service.exe $out/bin/service
    '';

    checkInputs = [
    ];

    propagatedBuildInputs = [
      piaf
      lwt
      yojson
    ];

    inherit doCheck;

    meta = {
      description = "Your service";
    };
  };
}

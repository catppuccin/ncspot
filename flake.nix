{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    catppuccin,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        lib = pkgs.lib;
        catppuccin-catwalk = catppuccin.packages.${system}.catwalk;
        catppuccin-whiskers = catppuccin.packages.${system}.whiskers;
      in {
        apps = rec {
          default = whiskers;

          catwalk = {
            type = "app";
            program = lib.getExe' catppuccin-catwalk "catwalk";
          };

          whiskers = {
            type = "app";
            program = lib.getExe' catppuccin-whiskers "whiskers";
          };
        };

        packages = {
          default = pkgs.stdenvNoCC.mkDerivation {
            name = "catppuccin-ncspot";
            version = "0.1.0";

            nativeBuildInputs = [catppuccin-whiskers];

            src = lib.cleanSourceWith {
              filter = (
                path: type:
                  ! (builtins.any
                    (r: (builtins.match r (builtins.baseNameOf path)) != null)
                    [
                      "assets"
                      "themes"
                    ])
              );
              src = lib.cleanSource ./.;
            };

            buildPhase = ''
              runHook preBuild
              whiskers $src/ncspot.tera
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              install -Dm644 -t $out themes/*.toml
              runHook postInstall
            '';
          };
        };

        devShell = pkgs.mkShellNoCC {
          packages = [
            catppuccin-catwalk
            catppuccin-whiskers
          ];
        };
      }
    );
}

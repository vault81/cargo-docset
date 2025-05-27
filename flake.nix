{
  description = "A Nix-flake-based Rust development environment";
  nixConfig = {
    extra-substituters = [
      "https://nixcache.vlt81.de"
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixcache.vlt81.de:nw0FfUpePtL6P3IMNT9X6oln0Wg9REZINtkkI9SisqQ="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
  };

  outputs =
    { self
    , nixpkgs
    , rust-overlay
    , flake-utils
    , devshell
    , ...
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        overlays = [
          rust-overlay.overlays.default
          devshell.overlays.default
          (final: prev: {
            customRustToolchain = prev.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          })
        ];
        config = {
          allowUnfree = true;
        };
        pkgs = import nixpkgs {
          inherit system overlays config;
        };
        buildInputs = with pkgs; [
          harfbuzz
          openssl
          sqlite
          mariadb
          zlib
          clang
          libclang
          gzip
          coreutils
          gdb
          glib
          glibc
        ];
        lib = pkgs.lib;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs;
            [
              customRustToolchain
              bacon
              binaryen
              cacert
              cargo-bloat
              cargo-docset
              cargo-machete
              cargo-limit
              cargo-deny
              cargo-edit
              cargo-watch
              cargo-make
              cargo-generate
              cargo-udeps
              cargo-outdated
              cargo-release
              rust-script
              calc
              fish
              inotify-tools
              mold
              pkg-config
              sccache
              unzip
            ]
            ++ buildInputs;

          buildInputs = buildInputs;
          shellHook = ''
            # export NIX_LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath buildInputs}:$NIX_LD_LIBRARY_PATH
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath buildInputs}"
            export MALLOC_CONF=thp:always,metadata_thp:always
          '';
        };
      });
}

#nix-env -I nixpkgs=. -p ./env -f test_packages.nix -i
nix-env -I nixpkgs=. -p ./env -f rbb_packages.nix -i

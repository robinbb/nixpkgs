with (import <nixpkgs> {});
import ./basic_packages.nix //
{ inherit
     nodejs
     gnused
     jq
     # mercurial
     # mysql55
     nix-generate-from-cpan
     ack
     postgresql
     # sqitchPg
     ghc
     stack
     # tmux
     pstree
     tree
     vim
     ;
  # cabal2nix = haskellPackages.cabal2nix ;
  cabal-install = haskellPackages.cabal-install ;
}

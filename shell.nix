{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  name = "comet.lua";

  buildInputs = with pkgs; [
    lua-language-server
  ];
}

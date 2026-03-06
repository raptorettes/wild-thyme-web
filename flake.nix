{
  description = "Nix based Godot dev template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] (system: function nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
        
          buildInputs = with pkgs; [
            godotPackages_4_6.godot
            bun
            just
          ];

          shellHook = ''
            echo ""
            #echo "/*"
            echo " * /-----"
            echo " * | Godot development environment"
            echo " * | Godot version: $(godot --version)"
            echo " * \-----"


            echo " * "
            echo " *  Start developing by running \`just dev\`"
            echo " *  Start testing by running \`just play\`"
            echo " *"
            #echo " */"
            echo ""
            just -l
            echo ""
          '';
        };
      });
    };
}


{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
  };


  outputs = { self, nixpkgs, home-manager, hyprland, ... } @ inputs: 
    let
      inherit (nixpkgs) lib;
      genSystems = lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];
      pkgsFor = genSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [
           self.overlays.default
            inputs.hyprland-protocols.overlays.default
          ];
        });
      mkDate = longDate: (lib.concatStringsSep "-" [
        (builtins.substring 0 4 longDate)
        (builtins.substring 4 2 longDate)
        (builtins.substring 6 2 longDate)
      ]);
      version = "0.pre" + "+date=" + (mkDate (self.lastModifiedDate or "19700101")) + "_" + (self.shortRev or         "dirty");

      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations = {
        caramell = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.caramell = {
                imports = [./home.nix];
              };
            }
        hyprland.nixosModules.default
        { programs.hyprland.enable = true; }
          ];
        };
      };

      overlays.default = final: prev: {
      xdg-desktop-portal-hyprland = final.callPackage ./nix/default.nix {
        inherit (final) hyprland-protocols hyprland-share-picker;
        inherit version;
      };

      hyprland-share-picker = final.libsForQt5.callPackage ./nix/hyprland-share-picker.nix {inherit version;};
    };

    packages = genSystems (system:
      (self.overlays.default pkgsFor.${system} pkgsFor.${system})
      // {default = self.packages.${system}.xdg-desktop-portal-hyprland;});

    formatter = genSystems (system: pkgsFor.${system}.alejandra);

    };
}

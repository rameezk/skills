{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );
    in
    {
      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          installer = pkgs.writeShellApplication {
            name = "skills-install";
            runtimeInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.findutils
              pkgs.gnugrep
            ];
            text = ''
              exec "${self}/scripts/install-direct.sh" --source "${self}" "$@"
            '';
          };
        in
        {
          install = {
            type = "app";
            program = "${installer}/bin/skills-install";
          };
          default = {
            type = "app";
            program = "${installer}/bin/skills-install";
          };
        }
      );

      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt);
    };
}

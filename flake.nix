{
  description = "Live Share support in Visual Studio Code";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux = {
      fix-vsliveshare = let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in
        pkgs.callPackage ./pkgs/fix-vsliveshare { inherit nixpkgs; };
    };

    nixosModule = { config, lib, ... }:
      let
        cfg = config.services.vsliveshare;
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        fix-vsliveshare = self.packages.x86_64-linux.fix-vsliveshare.override {
          inherit (cfg) extensionsDir;
        };
      in
        {
          options.services.vsliveshare = with lib.types; {
            enable = lib.mkEnableOption "VS Code Live Share extension";

            extensionsDir = lib.mkOption {
              type = str;
              default = "$HOME/.vscode/extensions";
              description = ''
                The VS Code extensions directory.
                CAUTION: The fix will remove ms-vsliveshare.vsliveshare-* inside this directory!
              '';
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = with pkgs; [ bash desktop-file-utils xlibs.xprop fix-vsliveshare ];

            services.gnome3.gnome-keyring.enable = true;

            systemd.user.services.auto-fix-vsliveshare = {
              description = "Automatically fix the VS Code Live Share extension";
              serviceConfig = {
                ExecStart = "${pkgs.callPackage (./pkgs/auto-fix-vsliveshare) {
                  inherit fix-vsliveshare;
                  inherit (cfg) extensionsDir;
                }}";
              };
              wantedBy = [ "graphical-session.target" ];
            };
          };
        };
  };
}

{
  description = "jiasuqi devel";

  inputs = {nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";};

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [];
      };

    targetSystems = ["aarch64-linux" "x86_64-linux"];
  in {
    devShells = nixpkgs.lib.genAttrs targetSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        name = "jiasuqi-devel";
        nativeBuildInputs = with pkgs; [
          qemu_kvm
          virt-viewer
          gnome.zenity
          ipset
          iptables
          iproute2
          dnsutils
          openssh
          aria2
          xz
        ];
      };
    });
  };
}
# https://discourse.nixos.org/t/packaging-a-bash-script-issues/20224/3


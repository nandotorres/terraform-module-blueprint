{
  description = "Terraform module implementation reference";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "terraform";
          };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              terraform
              tflint
              trivy
              conftest
              terraform-docs
              go
              prek
              gnumake
              git
              cacert
            ];
          };
        }
      );
    };
}

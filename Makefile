format:
	alejandra .

deploy-vps:
	nixos-rebuild switch  --flake .#vps --target-host root@vps

deploy-mlab:
	nixos-rebuild switch  --flake .#mlab --target-host root@mlab

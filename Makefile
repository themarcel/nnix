format:
	alejandra .

deploy-vps:
	nixos-rebuild switch  --flake .#vps --target-host root@vps


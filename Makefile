format:
	alejandra .

deploy-vps:
	nixos-rebuild switch  --flake .#infected-vps --target-host root@marcel-cool-vps


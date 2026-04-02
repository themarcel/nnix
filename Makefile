format:
	alejandra .

deploy-vps:
	nixos-rebuild switch  --flake .#vps --target-host root@vps

deploy-mlab:
	@if ssh -q -o ConnectTimeout=5 root@mlab-local exit 2>/dev/null; then \
		nixos-rebuild switch  --flake .#mlab --target-host root@mlab-local; \
	else \
		nixos-rebuild switch  --flake .#mlab --target-host root@mlab; \
	fi

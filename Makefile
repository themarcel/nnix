format:
	alejandra .

vps:
	nixos-rebuild switch  --flake .#vps --target-host root@vps

mlab:
	@if ssh -q -o ConnectTimeout=5 root@mlab-local exit 2>/dev/null; then \
		nixos-rebuild switch  --flake .#mlab --target-host root@mlab-local; \
	else \
		nixos-rebuild switch  --flake .#mlab --target-host root@mlab; \
	fi

droid:
	ssh droid "nix-on-droid switch --flake ~/.config/nix-on-droid#default"

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
	nix build .#nixOnDroidConfigurations.default.activationPackage --impure
	nix copy --to "ssh://nix-on-droid@droid?remote-program=/data/data/com.termux.nix/files/home/.nix-profile/bin/nix-store" ./result
	ssh droid "$$(readlink -f result)/activate"

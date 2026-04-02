#!/usr/bin/env bash

set -e

# Check if local mlab is available
if ssh -q -o ConnectTimeout=5 root@mlab-local exit 2>/dev/null; then
	echo "✓ Local mlab server (192.168.1.199) is reachable"
	nixos-rebuild switch --flake .#mlab --target-host root@mlab-local
elif ssh -q -o ConnectTimeout=5 root@mlab exit 2>/dev/null; then
	echo "✓ Remote mlab server (ssh.marcel.cool) is reachable"
	nixos-rebuild switch --flake .#mlab --target-host root@mlab
else
	echo "Neither local nor remote mlab server is reachable"
	echo "Please check your network connection and SSH configuration"
	exit 1
fi

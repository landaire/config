rebuild-caladan:
	nix run 'nix-darwin/master#darwin-rebuild' -- switch --flake .#caladan

rebuild-salusa:
	nix run 'nix-darwin/master#darwin-rebuild' -- switch --flake .#salusa

rebuild-work:
	nix run 'nix-darwin/master#darwin-rebuild' -- switch --flake .#landerb-mac2

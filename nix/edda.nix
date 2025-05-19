{
	darwin.homebrew-casks = [ "nextcloud" "steam" ];
	home-manager = { lib, pkgs, osConfig, osClass, ... }: let
		inherit (osConfig) local-os;
	in {
		home.stateVersion = "25.05";

		# packages installed outside of nix: bitwarden
		home.packages = with pkgs; [
			eza htop ncdu git curl direnv just
			ripgrep httpie p7zip jq jless
			helix
			nerd-fonts.fira-mono
			fortune cowsay
			pass
		]
		++ lib.lists.optionals local-os.gui [ firefox zed-editor python313 telegram-desktop mpv ]
		++ lib.lists.optionals (local-os.gui && osClass == "darwin") [ iterm2 ];
		fonts.fontconfig.enable = true;

		home.shellAliases = lib.mkMerge [
			{
				ls = "eza";
				ll = "eza -laag";
				legit = "git";
				legut = "git";
				yeet = "rm -rf";
			}
			(lib.mkIf local-os.gui { code = "zeditor"; })
			(lib.mkIf (osClass == "darwin") {
				needu-os = "nix flake update --flake ~/Documents/infrastructure/metal/os";
				needu-apply = "darwin-rebuild switch --flake ~/Documents/infrastructure/metal/os#${local-os.hostname}";
			})
		];
		home.sessionVariables = {
			"EDITOR" = "hx";
		};
		programs.fish = {
			enable = true;
			interactiveShellInit = ''
				function fish_prompt
					set -l last_status $status

					set -g __fish_git_prompt_showdirtystate	1
					set -g __fish_git_prompt_showuntrackedfiles 1

					set -f lambda_colors green red
					if fish_is_root_user
						set -f lambda_colors magenta red
					end

					if test $last_status -eq 0
						set -f lambda_color $lambda_colors[1]
					else
						set -f lambda_color $lambda_colors[2]
					end

					set -f tags (string join ',' $prompt_tags)
					if test -n "$tags"
						set -f tags " {$tags}"
					end

					echo "$(set_color yellow)$PWD""$(set_color --bold white)$(fish_git_prompt)$(set_color normal)""$(set_color white)$tags$(set_color normal)""$(set_color --bold green) λ$(set_color normal) "
				end

				function fish_right_prompt
					set -l last_status $status

					printf '[%s] ' $last_status
					set_color green
					date +'%H:%M:%S'
					set_color normal
				end

				function fish_greeting
					set joke (curl --silent --max-time 1 -H 'Accept: text/plain' https://icanhazdadjoke.com/ || fortune)
					echo $joke | cowsay -f moose.cow
				end

				direnv hook fish | source
			'';
			functions = {
				load_ssh = "ssh-add ~/.ssh/${local-os.hostname}";
			};
		};

		programs.git = {
			enable = true;
			delta.enable = true;
			aliases = {
				"fap" = "fetch --all --prune";
			};
			extraConfig = {
				credential = {
					helper = ''!f() { echo username=git; echo "password=$GIT_PAT"; }; f'';
				};
			};
		};

		programs.home-manager.enable = true;
	};
}

{
	darwin.homebrew-casks = [ "nextcloud" "steam" "slack" ];
	home-manager = { lib, pkgs, osConfig, osClass, ... }: let
		inherit (osConfig) local-os;
	in {
		home.stateVersion = "25.05";

		# packages installed outside of nix: bitwarden
		home.packages = with pkgs; [
			eza htop ncdu p7zip jq jless ripgrep
			curl httpie git
			direnv just pass podman dive
			helix
			nerd-fonts.fira-mono
			fortune cowsay
		]
		++ lib.lists.optionals local-os.gui [
			python313
			firefox zed-editor dbeaver-bin
			telegram-desktop mpv
		]
		++ lib.lists.optionals (local-os.gui && osClass == "darwin") [
			iterm2
		];
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
				needu-apply = "sudo darwin-rebuild switch --flake ~/Documents/infrastructure/metal/os#${local-os.hostname}";
			})
		];
		home.sessionVariables = {
			"EDITOR" = "hx";
		};
		programs.fish = {
			enable = true;
			loginShellInit = ''
				fish_add_path "$HOME/.local/bin"
			'';
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
				podrun = ''
					set -f podman_flags
					set -f podman_args
					set -f seen_double_dash 0

					for a in $argv[2..-1]
						if test "x$a" = 'x--'
							set -f seen_double_dash 1
						else
							if test "$seen_double_dash" = '1'
								set -a podman_args $a
							else
								set -a podman_flags $a
							end
						end
					end

					podman build --tag "localhost/podrun" --file "$argv[1]" . || return 1
					podman run --interactive --tty --rm $podman_flags "localhost/podrun" $podman_args
				'';
				dive-local = ''
					podman save $argv[1] | dive docker-archive:///dev/stdin
				'';
			};
		};
		programs.direnv = {
			enable = true;
			# enableFishIntegration = true;
			nix-direnv.enable = true;
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
			ignores = [
				".direnv"
			];
		};

		programs.helix = {
			enable = true;
			settings = {
				theme = "ao";
			};
		};

		programs.zed-editor = {
			enable = local-os.gui;
			userSettings = {
				"telemetry" = {
					"metrics" = false;
					"diagnostics" = false;
				};
				"ui_font_size" = 13;
				"buffer_font_size" = 13;
				"theme" = {
					"mode" = "system";
					"light" = "One Light";
					"dark" = "One Dark";
				};
				"tab_size" = 4;
				"hard_tabs" = true;
				"format_on_save" = "off";
				"languages" = {
					"Nix" = {
						"language_servers" = [];
					};
					"YAML" = {
						"tab_size" = 2;
						"hard_tabs" = false;
					};
					"Terraform" = {
						"tab_size" = 2;
						"hard_tabs" = false;
					};
				};
				"lsp" = {
					"rust-analyzer" = {
						"binary" = {
							"path" = "rust-analyzer";
						};
					};
				};
			};
			userKeymaps = [
				{
					"context" = "Editor";
					"bindings" = {
						"cmd-alt-left" = "pane::GoBack";
						"cmd-alt-right" = "pane::GoForward";
					};
				}
			];
		};

		programs.home-manager.enable = true;
	};
}

switch $system_preset
case linux
	set -gx SSH_AGENT_ENV "$HOME/.ssh/agent-env"

	keychain --eval --noask --quiet > "$SSH_AGENT_ENV"
	source "$SSH_AGENT_ENV"
end

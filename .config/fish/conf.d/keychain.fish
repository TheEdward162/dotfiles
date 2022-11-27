set SSH_AGENT_ENV "$HOME/.ssh/agent-env"

keychain --eval --noask --quiet > "$SSH_AGENT_ENV"
source "$SSH_AGENT_ENV"

function load_ssh
	keychain id_ed25519_lavusedu id_rsa_edwardium id_rsa_leviathan id_ed25519_applifting
end

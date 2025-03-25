switch $system_preset
case macos
	function load_ssh
		ssh-add ~/.ssh/id_ed25519_applifting ~/.ssh/wadebook2
	end
case linux
	function load_ssh
		keychain id_ed25519_lavusedu id_rsa_edwardium id_ed25519_leviathan id_ed25519_applifting
	end
end

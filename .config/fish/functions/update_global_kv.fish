function update_global_kv
	set -l name $argv[1]
	set -l prefix $argv[2]
	set -l value $argv[3]

	set -f new_list
	set -f add_to_list 0
	if test -z $value
		set -f add_to_list 1
	end

	for v in $$name
		if string match "$prefix*" $v >/dev/null
			if test $add_to_list -eq 0
				set -f new_list $new_list "$prefix$value"
				set -f add_to_list 1
			end
		else
			set -f new_list $new_list $v
		end
	end

	if test $add_to_list -eq 0
		set -f new_list "$prefix$value" $new_list
	end

	set -g $name $new_list
end

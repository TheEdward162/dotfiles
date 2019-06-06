#!/bin/env bash

ac_path="/sys/class/power_supply/AC"
battery_path="/sys/class/power_supply/BAT0"

get_charge_now() {
	local charge_now=$(cat "${battery_path}/charge_now")
	local charge_full=$(cat "${battery_path}/charge_full")

	local charge_percent=$(echo "scale=2; ${charge_now}/${charge_full} * 100" | bc)
	echo "$charge_percent"
}

get_charge_original() {
	local charge_full=$(cat "${battery_path}/charge_full")
	local charge_full_design=$(cat "${battery_path}/charge_full_design")

	local charge_design_percent=$(echo "scale=2; ${charge_full}/${charge_full_design} * 100" | bc)
	echo "$charge_design_percent"
}

get_draw_now() {
	local ac_online=$(cat ${ac_path}/online)

	if [[ "$ac_online" -eq 1 ]]; then
		echo "Unknown"
		return 1
	else
		local current_now=$(cat /sys/class/power_supply/BAT0/current_now)
		local voltage_now=$(cat /sys/class/power_supply/BAT0/voltage_now)

		local battery_consumption=$(echo "scale=2; ${current_now} * ${voltage_now} / 1000000000000" | bc)

		echo "$battery_consumption"
	fi
}

pretty_charge_now() {
	local charge_now=$(get_charge_now)
	echo "Charge now: ${charge_now}%"
}

pretty_charge_original() {
	local charge_original=$(get_charge_original)
	echo "Charge full design: ${charge_original}%"
}

pretty_draw_now() {
	local draw_now=$(get_draw_now)
	if [[ $draw_now == "Unknown" ]]; then
		echo "Unknown"
		return 1
	else
		echo "Draw now: ${draw_now} W"
	fi
}

output_pretty() {
	local which=${1:-all}

	case "$which" in
		n|now)
			pretty_charge_now
		;;

		o|orig|original)
			pretty_charge_original
		;;

		d|draw)
			pretty_draw_now
		;;

		*)
			pretty_charge_now
			pretty_charge_original
			pretty_draw_now
		;;
	esac
}

if [[ $# -gt 0 ]]; then
	case "$1" in
		n|now)
			get_charge_now
		;;

		o|orig|original)
			get_charge_original
		;;

		d|draw)
			get_draw_now
		;;

		p|pretty)
			output_pretty "$2"
		;;

		*)
			get_charge_now
			get_charge_original
			get_draw_now
		;;
	esac
else
	output_pretty all
fi
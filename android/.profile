alias yt='yt-dlp --paths storage/downloads/Ys'
alias gl='gallery-dl --destination storage/downloads/Ys'

transcode_dcim() {
	cd ~/storage/dcim/Camera
	if [ -z "$1" ]; then
		ls -sh *.mp4
	else
		ffmpeg -i "$1.mp4" -vcodec libx265 -crf 28 "$1.small.mp4"
		ls -sh "$1"*.mp4
	fi
	cd -
}

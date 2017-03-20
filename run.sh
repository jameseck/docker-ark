#!/usr/bin/env bash
echo "###########################################################################"
echo "# Ark Server - " `date`
echo "###########################################################################"
[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

export TERM=linux

if [ ! -w /ark ]; then
	echo "[Error] Can't access ark directory. Check permissions on your mapped directory with /ark"
	exit 1
fi

# Change working directory to /ark to allow relative path
cd /ark

# Add a template directory to store the last version of config file
[ ! -d /ark/template ] && mkdir /ark/template
# We overwrite the template file each time
cp /home/steam/arkmanager.cfg /ark/template/arkmanager.cfg
cp /home/steam/crontab /ark/template/crontab
# Creating directory tree && symbolic link
[ ! -f /ark/arkmanager.cfg ] && cp /home/steam/arkmanager.cfg /ark/arkmanager.cfg
[ ! -d /ark/log ] && mkdir /ark/log
[ ! -d /ark/backup ] && mkdir /ark/backup
[ ! -d /ark/server/ShooterGame/Content/Mods ] && mkdir -p /ark/server/ShooterGame/Content/Mods
[ ! -f /ark/Game.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/Game.ini Game.ini
[ ! -d /ark/server/ShooterGame/Saved/Config/LinuxServer ] && mkdir -p /ark/server/ShooterGame/Saved/Config/LinuxServer
[ ! -f /ark/GameUserSettings.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini GameUserSettings.ini

cp -f /ark/arkmanager.cfg /etc/arkmanager/instances/main.cfg


if [ ! -d "/ark/server"  ] || [ ! -f "/ark/server/arkversion" ];then
	arkmanager install @all
	# Create mod dir
	mkdir /ark/server/ShooterGame/Content/Mods
	# Download mods
	arkmanager update --update-mods @all
else

	if [ ${BACKUPONSTART} -eq 1 ]; then
		echo "[Backup]"
		arkmanager backup @all
	fi

	if [ ${UPDATEONSTART} -eq 1 ]; then
		echo "[Update]"
		arkmanager update --update-mods @all
	fi
fi

# If there is uncommented line in the file
CRONNUMBER=`grep -v "^#" /ark/crontab | wc -l`
if [ $CRONNUMBER -gt 0 ]; then
	echo "Loading crontab..."
	# We load the crontab file if it exist.
	crontab /ark/crontab
	# Cron is attached to this process
	sudo cron -f &
else
	echo "No crontab set."
fi

# Launching ark server
arkmanager start @all


# Stop server in case of signal INT or TERM
echo "Waiting..."
trap 'arkmanager stop;' INT
trap 'arkmanager stop' TERM

read < /tmp/FIFO &
wait

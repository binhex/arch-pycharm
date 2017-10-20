#!/bin/bash

# exit script if return code != 0
set -e

# build scripts
####

# download build scripts from github
curly.sh -rc 6 -rw 10 -of /tmp/scripts-master.zip -url https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /root/

# pacman packages
####

# define pacman packages
pacman_packages="git python2 python2-pip python2-packaging python3 python-pip python-packaging tk"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aor packages
####

# define arch official repo (aor) packages
aor_packages=""

# call aor script (arch official repo)
source /root/aor.sh

# aur packages
####

# define aur packages
aur_packages="pycharm-community"

# call aur install script (arch user repo)
source /root/aur.sh

# config pycharm
####

# set pycharm path selector, this changes the path used by pycharm to check for a custom idea.properties file
# the path is constructed from /home/nobody/.<idea.paths.selector value>/config/ so the idea.properties file then needs
# to be located in /home/nobody/.config/pycharm/idea.properties, note double backslash to escape end backslash
sed -i -e 's~-Didea.paths.selector=.*~-Didea.paths.selector=config/pycharm \\~g' /opt/pycharm-community/bin/pycharm.sh

# set pycharm paths for config, plugins, system and log, note the location of the idea.properties
# file is constructed from the idea.paths.selector value, as shown above.
mkdir -p /home/nobody/.config/pycharm/config
echo "idea.config.path=/config/pycharm/config" > /home/nobody/.config/pycharm/config/idea.properties
echo "idea.plugins.path=/config/pycharm/config/plugins" >> /home/nobody/.config/pycharm/config/idea.properties
echo "idea.system.path=/config/pycharm/system" >> /home/nobody/.config/pycharm/config/idea.properties
echo "idea.log.path=/config/pycharm/system/log" >> /home/nobody/.config/pycharm/config/idea.properties

cat <<'EOF' > /tmp/startcmd_heredoc
# check if recent projects directory config file exists, if it doesnt we assume
# pycharm hasn't been run yet and thus set default location for future projects to
# external volume mapping.
if [ ! -f /config/pycharm/config/options/recentProjectDirectories.xml ]; then
	mkdir -p /config/pycharm/config/options
	cp /home/nobody/recentProjectDirectories.xml /config/pycharm/config/options/recentProjectDirectories.xml
fi

# run pycharm
/usr/bin/pycharm
EOF

# replace startcmd placeholder string with contents of file (here doc)
sed -i '/<!-- STARTCMD_PLACEHOLDER -->/{
    s/<!-- STARTCMD_PLACEHOLDER -->//g
    r /tmp/startcmd_heredoc
}' /home/nobody/start.sh
rm /tmp/startcmd_heredoc

# config novnc
###

# overwrite novnc favicon with application favicon
cp /home/nobody/favicon.ico /usr/share/novnc/

# config openbox
####

cat <<'EOF' > /tmp/menu_heredoc
    <item label="PyCharm">
    <action name="Execute">
      <command>pycharm</command>
      <startupnotify>
        <enabled>yes</enabled>
      </startupnotify>
    </action>
    </item>
EOF

# replace menu placeholder string with contents of file (here doc)
sed -i '/<!-- APPLICATIONS_PLACEHOLDER -->/{
    s/<!-- APPLICATIONS_PLACEHOLDER -->//g
    r /tmp/menu_heredoc
}' /home/nobody/.config/openbox/menu.xml
rm /tmp/menu_heredoc

# container perms
####

# create file with contets of here doc
cat <<'EOF' > /tmp/permissions_heredoc
echo "[info] Setting permissions on files/folders inside container..." | ts '%Y-%m-%d %H:%M:%.S'

chown -R "${PUID}":"${PGID}" /tmp /usr/share/themes /home/nobody /usr/share/novnc /opt/pycharm-community/ /usr/share/applications/ /etc/xdg
chmod -R 775 /tmp /usr/share/themes /home/nobody /usr/share/novnc /opt/pycharm-community/ /usr/share/applications/ /etc/xdg

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /root/init.sh
rm /tmp/permissions_heredoc

# env vars
####

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /usr/share/gtk-doc/*
rm -rf /tmp/*

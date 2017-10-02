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

# replace placeholder with path to executable we want to run on startup of openbox
sed -i -e 's~# STARTCMD_PLACEHOLDER~/usr/bin/pycharm~g' /home/nobody/start.sh

# set pycharm paths to users home directory (note having issues setting this in /home/nobody thus the edit to global file)
sed -i -e 's~.*idea.config.path.*~idea.config.path=/home/nobody/.PyCharmCE/config~g' /opt/pycharm-community/bin/idea.properties
sed -i -e 's~.*idea.system.path.*~idea.system.path=/home/nobody/.PyCharmCE/system~g' /opt/pycharm-community/bin/idea.properties
sed -i -e 's~.*idea.plugins.path.*~idea.plugins.path=${idea.config.path}/plugins~g' /opt/pycharm-community/bin/idea.properties
sed -i -e 's~.*idea.log.path.*~idea.log.path=${idea.system.path}/log~g' /opt/pycharm-community/bin/idea.properties

# container perms
####

# create file with contets of here doc
cat <<'EOF' > /tmp/permissions_heredoc
echo "[info] Setting permissions on files/folders inside container..." | ts '%Y-%m-%d %H:%M:%.S'

chown -R "${PUID}":"${PGID}" /tmp /usr/share/themes /home/nobody /usr/share/novnc /etc/xdg/openbox/ /opt/pycharm-community/ /usr/share/applications/
chmod -R 775 /tmp /usr/share/themes /home/nobody /usr/share/novnc /etc/xdg/openbox/ /opt/pycharm-community/ /usr/share/applications/

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

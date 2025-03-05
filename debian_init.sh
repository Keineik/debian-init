SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/debian_init.env

yell() { echo -e "$0: $*" >&2; }
die() { yell "\n$*"; exit 111; }
try() { "$@" || die "cannot $*"; }
exec_as_root() { try echo ${ROOT_PASSWORD} | su root -c "$su_command"; }

#====================================================================
#======= Remove cdrom from sources.list to enable apt install =======
#====================================================================
# Thanks to None1975: https://forums.debian.net/viewtopic.php?t=155958
echo -e "Upgrading packages...";
res=$(sudo apt-get update && sudo apt-get upgrade -y 2>&1 1>/dev/null);
if [[ $res == *"cdrom://"* ]]; then
  echo -e "Removing cdrom from sources.list...";
  sudo sed -ie "/^deb cdrom/ s/./# &/" /etc/apt/sources.list;
  echo -e "Retrying..."
  sudo apt-get update && sudo apt-get upgrade -y;
fi
echo -e "Done\n";

#==================================================
#======= Removing applications and packages =======
#==================================================
sudo apt-get remove --purge -y "libreoffice*";
sudo apt-get remove --purge -y akregator korganizer;
sudo apt-get clean -y;
sudo apt-get autoremove -y;

#==========================================
#======= Installing useful packages =======
#==========================================
#=====> Install curl
sudo apt-get install curl -y;

#=====> Install power managing packages
sudo apt install power-profiles-daemon -y;

#=====> Install flatpak and Plasma Discover flatpak plugin
sudo apt-get install flatpak plasma-discover-backend-flatpak -y;
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo;

#=======================================
#======= Installing applications =======
#=======================================
#=====> Install synaptic
sudo apt-get install synaptic -y;

#=====> Brave browser
flatpak install flathub com.brave.Browser -y;

#=====> Discord
flatpak install flathub com.discordapp.Discord -y;

#=====> Ibus Bamboo for Vietnamese typing
# src=https://software.opensuse.org//download.html?project=home%3Alamlng&package=ibus-bamboo
echo 'deb http://download.opensuse.org/repositories/home:/lamlng/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/home:lamlng.list
curl -fsSL https://download.opensuse.org/repositories/home:lamlng/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_lamlng.gpg > /dev/null
sudo apt-get update
sudo apt-get install -y ibus-bamboo

#====================================
#======= Installing dev tools =======
#====================================
#=====> Visual Studio Code
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg;
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/keyrings/microsoft-archive-keyring.gpg;
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list';
sudo apt-get update;
sudo apt-get install code;

#=====> Docker engine
# Set up docker's apt repository
# Add Docker's official GPG key
sudo apt-get update;
sudo apt-get install ca-certificates curl;
sudo install -m 0755 -d /etc/apt/keyrings;
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc;
sudo chmod a+r /etc/apt/keyrings/docker.asc;
# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null;
sudo apt-get update;
# Install docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y;
# Docker post-installation steps
sudo groupadd docker;
sudo usermod -aG docker $USER;
newgrp docker;

echo -e "Done\n"

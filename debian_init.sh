SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/debian_init.env

die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }
exec_as_root() { try echo ${ROOT_PASSWORD} | su root -c "$su_command"; }

#=======================================
#======= Add new user to sudoers =======
#=======================================
echo -e "Adding new user to sudoers..."
# check if NEW_SUDOERS did not exists in sudoers file yet
su_command="cat /etc/sudoers | grep ${NEW_SUDOERS}";
res=$(echo ${ROOT_PASSWORD} | su root -c "${su_command}");
if [ -z "$res" -a "$res" != " " ]; then
    # append NEW_SUDOERS to the sudoers file after the line containing root
    su_command="sed -ie \"/^root/a ${NEW_SUDOERS}\tALL=(ALL:ALL) ALL\" /etc/sudoers";
    exec_as_root
fi
echo -e "Done\n"

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

#====================================================
#======= Installing proprietary nvidia driver =======
#====================================================
echo -e "Installing proprietary nvidia driver"

sudo echo "\n" | sudo apt-add-repository contrib non-free non-free-firmware
# sudo apt install nvidia-open-kernel-dkms nvidia-driver firmware-misc-nonfree

#===============================================
#======= Installing desktop applications =======
#===============================================
echo -e "Upgrading packages...";
# Install prerequisite
sudo apt install curl;

# Instal brave
curl -fsS https://dl.brave.com/install.sh | sh;

# Install

echo -e "Done\n"

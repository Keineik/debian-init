SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/debian_init.env

yell() { echo -e "$0: $*" >&2; }
die() { yell "\n$*"; exit 111; }
try() { "$@" || die "cannot $*"; }
exec_as_root() { try echo ${ROOT_PASSWORD} | su root -c "$su_command"; }

#=======================================
#======= Add new user to sudoers =======
#=======================================
echo -e "Adding new user to sudoers..."
# if NEW_SUDOERS did not exists in sudoers file yet
su_command="cat /etc/sudoers | grep -c ${NEW_SUDOERS}";
res=$(echo ${ROOT_PASSWORD} | su root -c "${su_command}");
if [ $res -eq 0 ]; then
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

#===============================================
#======= Installing desktop applications =======
#===============================================
echo -e "Upgrading packages...";
# Install prerequisite
sudo apt-get install -y curl;

# Instal brave
curl -fsS https://dl.brave.com/install.sh | sh;

# Install vlc
sudo apt-get install -y vlc;

# Install ibus-bamboo for Vietnamese typing
# src=https://software.opensuse.org//download.html?project=home%3Alamlng&package=ibus-bamboo
echo 'deb http://download.opensuse.org/repositories/home:/lamlng/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/home:lamlng.list
curl -fsSL https://download.opensuse.org/repositories/home:lamlng/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_lamlng.gpg > /dev/null
sudo apt-get update
sudo apt-get install -y ibus-bamboo

echo -e "Done\n"

#====================================================
#======= Installing proprietary nvidia driver =======
#====================================================
echo -e "Installing proprietary nvidia driver"

sudo echo "\n" | sudo apt-add-repository contrib non-free non-free-firmware;
sudo apt update;
sudo apt install nvidia-open-kernel-dkms nvidia-driver firmware-misc-nonfree;

res=$(sudo cat /sys/module/nvidia_drm/parameters/modeset);
if [[ "$res" != "N" && "$res" != "Y" ]]; then
  # Prompt user to restart the device before continue
  die "Please restart the device to apply nvidia-driver.\nDisable SecureBoot if you have it enabled.";
elif [[ "$res" == "N" ]]; then
  # if options modeset=1 did not exists in the file
  res=$(sudo cat /etc/modprobe.d/nvidia-options.conf | sudo grep -c "options nvidia-drm modeset=1");
  if [[ $res -eq 0 ]]; then
    su_command="echo \"options nvidia-drm modeset=1\" >> /etc/modprobe.d/nvidia-options.conf";
    exec_as_root
  fi
  # Prompt user to restart the device before continue
  die "Please restart the device to apply modeset change.";
fi

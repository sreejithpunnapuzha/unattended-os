# -*- mode: sh -*-
# vi: set ft=sh:
#!/usr/bin/env bash
set -e

function distupgrade {
	# Update initial dependencies on server
	echo Update and upgrade from all repositories
	sudo apt update && sudo apt dist-upgrade -y
}

function linux_packages {
	sudo apt install -y linux-headers-$(uname -r) linux-image-extra-virtual
}

function basic_packages {
	sudo apt install -y apt-transport-https ca-certificates gnupg-agent software-properties-common vim wget curl rsync firefox squashfs-tools genisoimage exfat-utils cifs-utils \
	  build-essential git jq tmux libxmu6:i386 libpangox-1.0-0:i386 libpangoxft-1.0-0:i386 socat dkms aria2 uget gcc make binutils  sysstat vlc puddletag filezilla filezilla-common \
	  printer-driver-cups-pdf htop festival xsel unace unrar zip unzip p7zip-full p7zip-rar rar arj cabextract g++ gdb checkinstall cdbs devscripts dh-make fakeroot mdf2iso \
	  zlib1g-dev ipcalc dmg2img bzr iftop iperf pastebinit libreoffice libreoffice-java-common sharutils  mysql-workbench apport-retrace bchunk libffi-dev tree acpi ethtool iotop \
	  dstat tcpdump lsof apache2 nfs-kernel-server cmake cscope android-tools-adb android-tools-fastboot libavcodec-extra libdvdread4 samba cifs-utils fusesmb hplip-gui debhelper \
	  libreoffice-style-sifr quassel libdvd-pkg openssh-server dnsmasq nmap ovmf patch psmisc yarn gir1.2-polkit-1.0 libpolkit-agent-1-0 libpolkit-backend-1-0 libpolkit-gobject-1-0 \
	  libxslt1-dev libxml2-dev openssl libssl-dev vim vim-gtk hfsprogs net-tools mpack flac faac faad sox ffmpeg2theora libmpeg2-4 uudeview  mpeg3-utils mpegdemux liba52-dev mpeg2dec \
	  vorbis-tools id3v2 mpg321 mpg123 icedax lame libmad0 libjpeg-progs libdvdcss sqlite libavcodec-extra libdvd-pkg lzip lunzip libdvdnav4 gstreamer1.0-plugins-bad \
	  gstreamer1.0-plugins-ugly ffmpeg x264 x265 mencoder mplayer mplayer-gui intel-microcode iucode-tool
	sudo apt install -y --no-install-recommends h264enc
	sudo dpkg-reconfigure libdvd-pkg
}

function ubuntu_packages {
	# Accept MS Core Fonts EULA agreement
	sudo sh -c "echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections"
	sudo apt install -y gedit-plugins gedit-developer-plugins ubuntu-restricted-extras dconf-editor flashplugin-installer synaptic gparted meld gufw totem-plugins-extra \
	  ttf-mscorefonts-installer xul-ext-calendar-timezones xul-ext-lightning kazam plymouth-themes nautilus-admin gnome-tweak-tool gnome-shell-extension-dash-to-panel nautilus \
	  gdebi-core ubuntu-restricted-extras usb-creator-gtk va-driver-all vainfo libva2 gstreamer1.0-libav gstreamer1.0-vaapi
}

function kubuntu_packages {
	sudo apt install -y aptitude plasma-workspace-wallpapers kubuntu-restricted-extras preload ffmpegthumbs muon krita kbattleship kdevelop plymouth-themes
}

function kvm_packages {
	sudo apt install -y libvirt-bin libvirt-clients virtinst virt-manager ubuntu-vm-builder qemu-system qemu-kvm bridge-utils ssh-askpass libvirt-dev qemu-utils qemu \
	  libvirt0 python-libvirt virt-top libguestfs-tools cpu-checker libosinfo-bin libpangox-1.0-0 lib32z1 lib32ncurses5 retext ebtables dnsmasq-base
	sudo usermod -aG libvirt $(whoami)
}

function install_apps {
	wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
	curl -L https://packagecloud.io/slacktechnologies/slack/gpgkey | sudo apt-key add -
	wget -qO- https://deb.opera.com/archive.key | sudo apt-key add -
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
	wget -q -O - https://www.bunkus.org/gpg-pub-moritzbunkus.txt | sudo apt-key add -
	wget -q -O - https://zoom.us/linux/download/pubkey | sudo apt-key add -
	sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
	sudo sh -c 'echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
	sudo sh -c 'echo "deb https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" > /etc/apt/sources.list.d/slack.list'
	sudo sh -c 'echo "deb https://deb.opera.com/opera-stable/ stable non-free #Opera Browser (final releases)" > /etc/apt/sources.list.d/opera-stable.list'
	sudo sh -c 'echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" > /etc/apt/sources.list.d/docker-ce.list'
	sudo sh -c 'echo "deb https://download.sublimetext.com/ apt/stable/" > /etc/apt/sources.list.d/sublime-text.list'
	sudo sh -c 'echo "deb https://mkvtoolnix.download/ubuntu/ bionic main" >> /etc/apt/sources.list.d/mkvtoolnix.list'
	sudo apt update && sudo apt install -y google-chrome-stable code slack-desktop opera-stable docker-ce docker-ce-cli containerd.io sublime-text mkvtoolnix-gui
	wget -cP $HOME/Downloads/ https://download.jetbrains.com/python/pycharm-community-2019.3.3.tar.gz
	wget -cP $HOME/Downloads/ https://download.jetbrains.com/go/goland-2019.3.3.tar.gz
	wget -cP $HOME/Downloads/ https://dl.google.com/go/go1.14.linux-amd64.tar.gz
	sudo tar -C /opt -xzf $HOME/Downloads/pycharm-community*
	sudo tar -C /opt -xzf $HOME/Downloads/goland*
	sudo tar -C /usr/local -xzf $HOME/Downloads/go1.14.linux-amd64.tar.gz

	wget -cP $HOME/Downloads/ https://zoom.us/client/latest/zoom_amd64.deb
	wget -cP $HOME/Downloads/ https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
	wget -cP $HOME/Downloads/ https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.deb
	sudo apt install -y $HOME/Downloads/zoom_amd64.deb
	sudo apt install -y $HOME/Downloads/teamviewer_amd64.deb
	sudo apt install -y $HOME/Downloads/vagrant_2.2.7_x86_64.deb


	### Golang env
	#echo "export GOPATH=$HOME/Projects/goworks/" >> $HOME/.profile
	#echo "export GOBIN=$GOPATH/bin" >> $HOME/.profile
	#echo "export PATH=$PATH:$GOPATH:$GOBIN" >> $HOME/.profile
	#source .profile

	### Docker Configuration
	sudo usermod -aG docker $(whoami)
	sudo sed -i 's/ExecStart.*/ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ -H tcp:\/\/0.0.0.0:2375 --containerd=\/run\/containerd\/containerd.sock/' /lib/systemd/system/docker.service
	sudo systemctl daemon-reload
	sudo systemctl restart docker.service
}

function atomeditor {
	wget -qO - https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
	sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
	sudo apt update && sudo apt install -y atom
}

function virtualbox {
	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
	wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
	sudo sh -c 'echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian bionic contrib" > /etc/apt/sources.list.d/virtualbox.list'
	sudo apt update && sudo apt install -y virtualbox-6.1
}

function dell7530packages {
	sudo gpg --keyserver pool.sks-keyservers.net --recv-key F9FDA6BED73CDC22
	gpg -a --export F9FDA6BED73CDC22 | sudo apt-key add -
	sudo sh -c 'echo "deb http://dell.archive.canonical.com/updates/ bionic-dell-beaver-whitehaven public" > /etc/apt/sources.list.d/bionic-dell-beaver-whitehaven.list'
	sudo sh -c 'echo "deb http://dell.archive.canonical.com/updates/ bionic-dell public" > /etc/apt/sources.list.d/bionic-dell.list'
	sudo sh -c 'echo "deb http://dell.archive.canonical.com/updates/ bionic-dell-service public" > /etc/apt/sources.list.d/bionic-dell-service.list'
	sudo sh -c 'echo "deb http://oem.archive.canonical.com/updates/ bionic-oem public" > /etc/apt/sources.list.d/bionic-oem.list'
	sudo apt install -y dell-0831-meta dell-service-meta dell-recovery dell-recovery-casper somerville-meta workaround-wifi-hotkey tlp
	sudo apt install -y dell-eula oem-fix-eth-realtek-disabletlpr8153 oem-hotkey-osd oem-release oem-seventy-percent-brightness oem-ubuntu-boot-video \
	  oem-workaround-modprobe-blacklist-hid-sensor-accel-3d oem-workaround-pulseaudio-module-stream-restore oem-workaround-ubiquity-no-early-microcode \
	  workaround-systemd-bluetooth manage-distro-upgrade manage-estar-settings sosreport-oem timbuktu-meta tlp-config tlp-sensible ubuntu-recovery-grub-hotkey
}

function dell5300packages {
	sudo gpg --keyserver pool.sks-keyservers.net --recv-key F9FDA6BED73CDC22
	gpg -a --export F9FDA6BED73CDC22 | sudo apt-key add -
	sudo sh -c 'echo "deb http://dell.archive.canonical.com/updates/ bionic-dell-north-bay-13 public" > /etc/apt/sources.list.d/bionic-dell-north-bay-13.list'
	sudo sh -c 'echo "deb http://dell.archive.canonical.com/updates/ bionic-dell public" > /etc/apt/sources.list.d/bionic-dell.list'
	sudo sh -c 'echo "deb http://dell.archive.canonical.com/updates/ bionic-dell-service public" > /etc/apt/sources.list.d/bionic-dell-service.list'
	sudo sh -c 'echo "deb http://oem.archive.canonical.com/updates/ bionic-oem public" > /etc/apt/sources.list.d/bionic-oem.list'
}

function installpylib {
	sudo apt install -y python-pip python-dev python-setuptools python3-pip python3-dev python3-setuptools
	sudo pip3 install ansible virtualbmc lxml netaddr libvirt-python six virtualenv PyYAML
}

function fixvmware {
	sudo apt install libcanberra-gtk-module libcanberra-gtk3-module
	#sudo ln -s /usr/lib/x86_64-linux-gnu/gtk-2.0/modules/libcanberra-gtk-module.so /usr/lib/libcanberra-gtk-module.so
}

function installk8s {
	sudo curl -Lo /usr/local/bin/kind https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-$(uname)-amd64 && sudo chmod +x /usr/local/bin/kind
	sudo curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && sudo chmod +x /usr/local/bin/kubectl
	sudo curl -Lo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo chmod +x /usr/local/bin/minikube
}

# Install snap packages
#echo "Installing Snap packages"
#snap_packages=(
#  "snap-store"
#)

#for package in "${snap_packages[@]}"; do
#  sudo snap install -y "$package"
#done

if [ $# == 1 ]
then
	if [ $1 == 'ubuntu' ]
	then
		# Display message 'Setting up your new Ubuntu machine...'
		echo "Setting up your new Ubuntu machine..."
		distupgrade
		linux_packages
		ubuntu_packages
		kvm_packages
		install_apps
		installpylib
		installk8s
	elif [ $1 == 'kubuntu' ]
	then
		# Display message 'Setting up your new kubuntu machine...'
		echo "Setting up your new kubuntu machine..."
		distupgrade
		linux_packages
		kubuntu_packages
		virtualbox
		install_apps
		installpylib
		installk8s
	else
		echo "Invalid Option"
		echo "Supported varient are ubuntu and kubuntu"
		exit 1
	fi
else
	echo "usage: $0 ubuntu|kubuntu"
	exit 1
fi

release=$(lsb_release -c -s)

# Check if the script is running under Ubuntu 18.04 Bionic Beaver
if [ "$release" != "bionic" ] && [ "$release" != "disco" ] ; then
    >&2 echo -e "${RED}This script is made for Ubuntu 18.04/20.04!${NC}"
    exit 1
fi

# Enable UFW firewall
sudo ufw enable

# One final upgrade and cleanup for everything
echo "Upgrade & Cleaning Up"
sudo apt install -f
sudo apt -y -q upgrade && sudo apt -y -q autoremove && sudo apt -y autoclean && sudo apt -y clean

# Complete
echo "Setup Complete - !! Please restart your device to make sure all new software is working as expected !!"

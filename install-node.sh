#!/bin/sh

if [ "`whoami`" != "root" ]; then
  echo "This script must be run as root."
  exit 1
fi

# Setup environment variables
export   autoboot="`grep -ir systemd /boot`"
export   confdphp="/etc/php5/cli/conf.d"
export     koalad="/usr/local/koalad"
export libvirtphp="http://libvirt.org/sources/php/libvirt-php-0.4.8.tar.gz"
export     logdir="/var/log"
export   packages="bridge-utils build-essential git gnutls-bin libvirt-bin \
  libgpgme11-dev libvirt-dev libxml2-dev php-pear php5-cli php5-dev pkg-config \
  virtinst xsltproc"
export    systemd="/etc/systemd/system"
export        tmp="/tmp"
export    virtcap="`apt-cache pkgnames | grep -i 'xen-hypervisor\|qemu-kvm'`"
export         wd="`pwd`"

# Upgrade the current system
apt-get update
apt-get dist-upgrade -y

# Make sure required packages are installed
apt-get install -y ${packages}

# Clean-up after ourselves
apt-get autoremove -y
apt-get autoclean

# Test installed packages
for i in ${packages}; do
  if [ "`apt-cache pkgnames | grep \"${i}\"`" = "" ]; then
    echo "Package \"${i}\" was not found; exiting."
    exit 2
  fi
done

# Define variable for PHP executable
export php="`which php`"

# Search for PHP executable
if [ "${php}" = "" ]; then
  echo "Could not find PHP executable."
  exit 3
fi

# Make sure required directories are created
for i in "${confdphp}" "${tmp}"; do
  mkdir -p "$i";
done

# Upgrade any PECL extensions
pecl update-channels
pecl upgrade

# Install gnupg PECL extension
pecl install gnupg
echo "extension=gnupg.so" > "${confdphp}"/30-gnupg.ini

# Build and install libvirt-php
wget -O "${tmp}"/libvirt-php.tar.gz ${libvirtphp}
tar xvf "${tmp}"/libvirt-php.tar.gz -C "${tmp}"
cd "${tmp}"/libvirt-php*; ./configure; make install; cd "${wd}"
rm -rf "${tmp}"/libvirt-php*
echo "extension=libvirt-php.so" > "${confdphp}"/30-libvirtphp.ini

# Test PHP modules
for i in gnupg libvirt; do
  if [ "`\"${php}\" -m | grep \"${i}\"`" = "" ]; then
    echo "Could not find PHP module \"${i}\"; exiting."
    exit 4
  fi
done

# Upgrade koalad if it exists, otherwise clone it to "${koalad}"
if [ ! -d "${koalad}" ]; then
  git clone https://github.com/KoalaVM/koalad "${koalad}"
fi
cd "${koalad}"; git pull; git submodule update --init

# Setup a systemd unit to start koalad
echo "[Unit]
Description=koalad
Requires=libvirt-bin.service
After=libvirt-bin.service

[Service]
ExecStart=/usr/bin/php /usr/local/koalad/main.php
PIDFile=/usr/local/koalad/data/koalad.pid
Type=simple

[Install]
WantedBy=multi-user.target" > "${systemd}"/koalad.service
chmod 644 "${systemd}"/koalad.service
chown root:root "${systemd}"/koalad.service
systemctl enable koalad.service

echo
echo "#########################################################################"
echo "#                                                                       #"
echo "#                         Installation Complete!                        #"
echo "#                                                                       #"
echo "#         Open a ticket on GitHub if you encouter any problems.         #"
if [ "${virtcap}" = "" ] || [ "${autoboot}" = "" ]; then
echo "#                                                                       #"
echo "#  -------------------------------------------------------------------  #"
echo "#                                                                       #"
echo "#                                 NOTE:                                 #"
if [ "${virtcap}" = "" ]; then
echo "#                                                                       #"
echo "#  * No virtualization support is installed;                            #"
echo "#    Install one of the following:  xen-hypervisor-4.4 -or- qemu-kvm    #"
fi
if [ "${autoboot}" = "" ]; then
echo "#                                                                       #"
echo "#  * Use init=/bin/systemd to auto-start koalad on system boot.         #"
fi
fi
echo "#                                                                       #"
echo "#########################################################################"
echo

# Check existence of GPG public key
mkdir -p "${koalad}"/data/KoalaCore
export gpgpub="${koalad}/data/KoalaCore/gpg.pub"
touch ${gpgpub}
if [ "`wc -c \"${gpgpub}\" | awk '{print $1}'`" = "0" ]; then
  echo "Don't forget to install your master's GPG public key at:"
  echo "${koalad}"/data/KoalaCore/gpg.pub
  echo
fi

# Alert the user of a required reboot
if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
  cat /var/run/reboot-required.pkgs | xargs
fi

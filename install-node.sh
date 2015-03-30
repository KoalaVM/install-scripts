#!/bin/sh

if [ "`whoami`" != "root" ]; then
  echo "This script must be run as root."
  exit 1
fi

# Setup environment variables
export    confdphp="/etc/php5/conf.d"
export      koalad="/usr/local/koalad"
export  libvirtphp="http://libvirt.org/sources/php/libvirt-php-0.4.8.tar.gz"
export          wd="`pwd`"
export         tmp="/tmp"

# Upgrade the current system
apt-get update
apt-get dist-upgrade -y

# Make sure required packages are installed
apt-get install -y bridge-utils build-essential git gnutls-bin libvirt-bin \
  qemu-kvm libgpgme11-dev libvirt-dev libxml2-dev php-pear php5-cli php5-dev \
  pkg-config virtinst xen-hypervisor xsltproc

# Clean-up after ourselves
apt-get autoremove -y
apt-get autoclean

# Make sure required directories are created
for i in "${confdphp}" `basename "${koalad}"` "${tmp}"; do
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

# Upgrade koalad if it exists, otherwise clone it to "${koalad}"
if [ ! -d "${koalad}" ]; then
  git clone https://github.com/KoalaVM/koalad "${koalad}"
fi
cd "${koalad}"; git pull; git submodule update --init

# Alert the user of a required reboot
if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
  cat /var/run/reboot-required.pkgs | xargs
fi

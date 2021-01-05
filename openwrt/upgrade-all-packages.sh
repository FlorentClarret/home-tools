#!/bin/ash

source /etc/openwrt_release

echo "$DISTRIB_ID $DISTRIB_RELEASE"

rm -f /tmp/releases.html
wget -q https://downloads.openwrt.org/releases/ -O /tmp/releases.html
LATEST_RELEASE=`grep -o 'href="[0-9.]*/"' /tmp/releases.html | tail -1 | cut -d'"' -f2 | cut -d'/' -f1`
rm -f /tmp/releases.html

if [ $LATEST_RELEASE != $DISTRIB_RELEASE ]; then
    echo "New version available: $LATEST_RELEASE"
fi
echo ""

echo "Updating package list..."
opkg update > /dev/null

if [ `opkg list-upgradable | cut -d " " -f1 | wc -l` -gt 0 ]; then
  echo "Available updates:"
  opkg list-upgradable
  echo ""

  valid=0
  while [ $valid == 0 ]
  do
    read -n1 -s -p "Upgrade all available packages? [Y/n]" choice
    case $choice in
      y|Y|"" )
        valid=1
        echo ""
        echo "Upgrading all packages..."
        opkg list-upgradable | cut -d " " -f1 | xargs -r opkg upgrade
        ;;
      n|N)
        valid=1
        echo ""
        echo "Upgrade cancelled"
        ;;
      *)
        echo ""
        echo "Unknown input"
        ;;
    esac
  done
else
  echo "No updates available"
fi

opkg list-installed > /etc/config/installed-packages.txt

sync

#!/bin/bash

###############################################################################
#
#	Script:			centos7-init.sh
#	Author:			Nick Raymond
#	Last Updated:	18 JUL 2015
#	Description:	Used to configure a new CentOS box with Virtualbox on OSX
#
###############################################################################

#	[PARAMS] Configure variables using the parameters below
#HOSTNAME="pp-centos7-n01"
#IP="192.168.56.101"
#USER="puppet"
#PASS="puppet"
#ROOTPASS="puppet"
ISOPATH="/Users/nraymond-mac2k14/sandbox/images/iso/CentOS-7-x86_64-Everything-1503-01.iso"

#	Check for existing CentOS ISO
echo "Checking for CentOS ISO..."
ISOSUCCESS="echo ISO exists, checking for Homebrew..."
ISOFAILURE="echo ERROR: ISO file missing from path $ISOPATH"
if [ ! -f "$ISOPATH" ]; then
	$ISOFAILURE
	exit 1
else
	$ISOSUCCESS
fi

#	Check to see if Homebrew is already installed
HOMEBREWCHECK="brew info"
HOMEBREWSUCCESS="echo Homebrew installed, checking for wget..."
HOMEBREWFAILED="echo Homebrew not installed, installing from brew.sh..."
if $HOMEBREWCHECK > /dev/null; then
	$HOMEBREWSUCCESS
else
	$HOMEBREWFAILED
	GETHOMEBREW="ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)""
	$GETHOMEBREW
	$HOMEBREWSUCCESS
fi

#	Check for wget
WGETCHECK="brew list wget"
WGETSUCCESS="wget is installed, checking for Lynx..."
WGETFAILED="wget is not installed, installing..."
if $WGETCHECK > /dev/null; then
	echo $WGETSUCCESS
else
	echo $WGETFAILED
	brew install wget
	echo $WGETSUCCESS
fi
#	Check for wget
LYNXCHECK="brew list lynx"
LYNXSUCCESS="lynx is installed, checking for Virtualbox..."
LYNXFAILED="lynx is not installed, installing..."
if $LYNXCHECK > /dev/null; then
	echo $LYNXSUCCESS
else
	echo $LYNXFAILED
	brew install lynx
	echo $LYNXSUCCESS
fi

#	Check for current install of Virtualbox
vboxmanage --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Virtalbox was not found, checking for the latest version..."
	VBOXCHECK="missing"
else
	VBOXFULLVERSION="$(vboxmanage --version)"
	echo "Virtalbox version $VBOXFULLVERSION found, checking for the latest version..."
	VBOXCHECK="installed"
fi

#	Check for latest version of Virtualbox
VBOXINDEX="http://download.virtualbox.org/virtualbox"
VBOXVERSIONREGEX="[5-9]\.[0-9]\.[0-9]{1,2}/"
VBOXLATESTVERSION="$(lynx -dump -listonly $VBOXINDEX/ | egrep '[5-9]\.[0-9]\.[0-9]{1,2}/')"
echo $VBOXLATESTVERSION
if [[ $VBOXCHECK -eq "installed" ]]; then
	VBOXVERSION="$(echo $VBOXFULLVERSION | cut -d "r" -f 1)"
	VBOXBUILD="$(echo $VBOXFULLVERSION | cut -d "r" -f 2)"
fi

#wget -r --accept-regex '[5-9]\.[0-9]\.[0-99]/' --spider --no-check-certificate  $TEMPVAR
#VBOXVERREGEX="[5-9]\.[0-9]\.[0-99]"
#VBOXBUILDREGEX="[0-9]{6}"
#VBOXINSTALL="VirtualBox-$VBOXVERREGEX-$VBOXBUILDREGEX-OSX.dmg"
#VBOXGUEST="VBoxGuestAdditions_VBOXREGEX.iso"



#	If version is older than latest, install latest

#	
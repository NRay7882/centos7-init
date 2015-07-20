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

#	[PARAMS] Params for status messages
NOCOLOR='\033[0m'
GREENCOLOR='\033[1;92m'
OKECHO="echo -e [ ${GREENCOLOR}OK!${NOCOLOR} ] -	"
YELLOWCOLOR='\033[01;33m'
WARNECHO="echo -e [${YELLOWCOLOR}WARN:${NOCOLOR}] -	"
REDCOLOR='\033[1;91m'
ERRORECHO="echo -e [${REDCOLOR}ERROR${NOCOLOR}]	-	"
WHITECOLOR='\033[1;53m'
INFOECHO="echo -e [${WHITECOLOR}INFO:${NOCOLOR}] -	"

#	Check for existing CentOS ISO
$INFOECHO "Checking for CentOS ISO..."
ISOSUCCESS="${OKECHO}ISO exists, checking for Homebrew..."
ISOFAILURE="${ERRORECHO}ISO file missing from path $ISOPATH"
if [ ! -f "$ISOPATH" ]; then
	$ISOFAILURE
	exit 1
else
	$ISOSUCCESS
fi

#	Check to see if Homebrew is already installed
HOMEBREWCHECK="brew info"
HOMEBREWSUCCESS="${OKECHO} Homebrew installed, checking for wget..."
HOMEBREWFAILED="${WARNECHO} Homebrew not installed, installing from brew.sh..."
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
WGETSUCCESS="${OKECHO} wget is installed, checking for Lynx..."
WGETFAILED="${WARNECHO} wget is not installed, installing..."
if $WGETCHECK > /dev/null; then
	$WGETSUCCESS
else
	$WGETFAILED
	brew install wget
	$WGETSUCCESS
fi
#	Check for wget
LYNXCHECK="brew list lynx"
LYNXSUCCESS="${OKECHO} lynx is installed, checking for Virtualbox..."
LYNXFAILED="${WARNECHO} lynx is not installed, installing..."
if $LYNXCHECK > /dev/null; then
	$LYNXSUCCESS
else
	$LYNXFAILED
	brew install lynx
	$LYNXSUCCESS
fi

#	Check for current install of Virtualbox
vboxmanage --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	$WARNECHO "Virtalbox not found locally, checking for the latest version..."
	VBOXLOCALCHECK="missing"
else
	VBOXLOCALVERSION="$(vboxmanage --version)"
	VBOXLOCALVERSION="$(echo $VBOXLOCALVERSION | cut -d "r" -f 1)"
	$INFOECHO "Virtalbox local version $VBOXLOCALVERSION found, checking latest version..."
	VBOXLOCALCHECK="installed"
fi

#	Check for latest version of Virtualbox
VBOXINDEXURL="http://download.virtualbox.org/virtualbox"
VBOXINDEXREGEX='[5-9]\.[0-9]\.[0-9]{1,2}/'
VBOXMATCHURL="$(lynx -dump -listonly $VBOXINDEXURL/ | egrep $VBOXINDEXREGEX)"
VBOXREMOTEURL="$(echo $VBOXMATCHURL | cut -d " " -f 2)"
VBOXREMOTEURL="$(echo $VBOXREMOTEURL | cut -d "/" -f 1-5)"
VBOXREMOTEVERSION="$(echo -e $VBOXREMOTEURL/$VBOX | cut -d "/" -f 5)"
VBOXREMOTEREGEX="[VirtualBox]-$VBOXREMOTEVERSION-[0-9]{1,6}-OSX.dmg"
VBOXREMOTEFILENAME="$(lynx -crawl -dump -listonly $VBOXREMOTEURL/ | egrep $VBOXREMOTEREGEX)"
VBOXREMOTEFILENAME="$(echo $VBOXREMOTEFILENAME | cut -d " " -f 1)"
VBOXREMOTEFULLPATH="$VBOXREMOTEURL/$VBOXREMOTEFILENAME"
if ([[ $VBOXLOCALCHECK == "installed" ]] && [[ $VBOXLOCALVERSION == $VBOXREMOTEVERSION ]]); then
	$OKECHO "Remote version $VBOXREMOTEVERSION matches local version $VBOXLOCALVERSION, no action required...";
fi;

if ([[ $VBOXLOCALCHECK == "installed" ]] && [ $VBOXLOCALVERSION \< $VBOXREMOTEVERSION ]); then
	$WARNECHO "Remote version $VBOXREMOTEVERSION is newer than local version $VBOXLOCALVERSION, uninstalling old version...";
fi;



#	If version is older than latest, install latest
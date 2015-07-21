#!/bin/bash

###############################################################################
#
#	Script:			centos7-init.sh
#	Author:			Nick Raymond
#	Last Updated:	18 JUL 2015
#	Description:	Used to configure a new CentOS box with Virtualbox on OSX
#
###############################################################################

#< < < < < < < < C O N F I G U R E   P A R A M S   H E R E > > > > > > > > >
#	[PARAMS] Used for permissions, dir structure, and VM details (optional)
OSXUSER="nraymond-mac2k14" && USERPATH="/Users/${OSXUSER}" #dev account, admin/root access
ISOPATH="${USERPATH}/sandbox/images/iso/CentOS-7-x86_64-Everything-1503-01.iso" #path to VM ISO
#VBOXNAME="pp-centos7-n01" #name for VirtualBox instance
#VMHOSTNAME="pp-centos7-n01.base" #hostname
#VMIPADDR="192.168.56.101" #VM virtual IP
#VMUSER="puppet" #user id for VM
#VMPASS="puppet" #user password for VM
#VMROOTPASS="puppet" # set VM root password

###############################################################################
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

#	[Make temp dir]
$INFOECHO "Beginning init process, creating temp dir..."
RUNPATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
TEMPDIR="${RUNPATH}/temp"
if [ -d $TEMPDIR ]; then
	$WARNECHO "temp dir already found, removing..."
	rm -rf $TEMPDIR
	mktemp -d $TEMPDIR > /dev/null
	$OKECHO "temp dir created, adding ${OSXUSER} to admin group..."
else
	mktemp -d $TEMPDIR > /dev/null
	$OKECHO "temp dir created, adding ${OSXUSER} to admin group..."
fi
###############################################################################

#	Ensure user account is added to the admin group
sudo dseditgroup -o edit -a $OSXUSER -t user admin > /dev/null
$OKECHO "${OSXUSER} added, checking for CentOS ISO file..."

#	Check for existing admin sudoless password line
#%wheel	ALL=(ALL) NOPASSWD: ALL




#	Check for existing CentOS ISO
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

#	Determine if install, uninstall/install or nothing needs to occur
#	Latest, do nothing
if ([[ $VBOXLOCALCHECK == "installed" ]] && [[ $VBOXLOCALVERSION == $VBOXREMOTEVERSION ]]); then
	$OKECHO "Remote version $VBOXREMOTEVERSION matches local version $VBOXLOCALVERSION, no action required...";
fi;

#	If newer found, uninstall old version
if ([[ $VBOXLOCALCHECK == "installed" ]] && [ $VBOXLOCALVERSION \< $VBOXREMOTEVERSION ]); then
	$WARNECHO "Remote version $VBOXREMOTEVERSION is newer than local version $VBOXLOCALVERSION, uninstalling old version...";

#	Create items list to be removed
	TEMPVBOXRAW="${TEMPDIR}/virtualboxitems-raw.txt"
	TEMPVBOXLIST="${TEMPDIR}/virtualboxitems-list.txt"
	mdfind -name "VirtualBox" > $TEMPVBOXRAW
	VBOXDELETEARRAY=(
					[backup="${USERPATH}/VirtualBox VMs"]
					[remove]="/Applications/VirtualBox.app"
					[remove]="/Library/Application Support/VirtualBox"
					[remove]="${USERPATH}/Library/LaunchAgents/org.virtualbox.vboxwebsrv.plist"
					[remove]="${USERPATH}/Library/VirtualBox"
					[remove]="/usr/local/bin/VirtualBox"

		)
	echo ${VBOXDELETEARRAY[0]}
	grep  $TEMPVBOXRAW -R | cut -d ":" -f 2 >> $TEMPVBOXLIST && 
	grep  $TEMPVBOXRAW -R | cut -d ":" -f 2 >> $TEMPVBOXLIST && 
	grep  $TEMPVBOXRAW -R | cut -d ":" -f 2 >> $TEMPVBOXLIST && 
	grep  $TEMPVBOXRAW -R | cut -d ":" -f 2 >> $TEMPVBOXLIST && 
	grep  $TEMPVBOXRAW -R | cut -d ":" -f 2 >> $TEMPVBOXLIST
fi;



#	If version is older than latest, install latest
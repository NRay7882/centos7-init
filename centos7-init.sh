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
OSXROOTPASS=$1 # Root pw for assigning permissions, sudoless access
OSXUSER="Macbook" && USERPATH="/Users/${OSXUSER}" # Dev account, admin/root access
ISOPATH="${USERPATH}/sandbox/images/iso/CentOS-7-x86_64-Everything-1503-01.iso" #path to VM ISO
#VBOXNAME="pp-centos7-n01" #name for VirtualBox instance
#VMHOSTNAME="pp-centos7-n01.base" #hostname
#VMIPADDR="192.168.56.101" #VM virtual IP
#VMUSER="puppet" #user id for VM
#VMPASS="puppet" #user password for VM
#VMROOTPASS="puppet" #set VM root password
VMFILEPATH="${USERPATH}/VirtualBox VMs" #Set to where your VM image files are stored

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
	$OKECHO "temp dir created, adding $OSXUSER to admin group..."
else
	mktemp -d $TEMPDIR > /dev/null
	$OKECHO "temp dir created, adding $OSXUSER to admin group..."
fi
###############################################################################

#	Add dev user account to %admin group
echo "${OSXROOTPASS}\n" sudo -S dseditgroup -o edit -a $OSXUSER -t user admin > /dev/null 2>&1
$OKECHO "${OSXUSER} user added, ensuring passwordless sudo access..."

#	Ensure dev user has passwordless sudo access
OSXSUDOLESS="^%admin\sALL=(ALL)\sNOPASSWD:\sALL"
LINE=$(echo $OSXROOTPASS > /dev/null 2>&1 | sudo -S grep $OSXSUDOLESS /etc/sudoers) > /dev/null 2>&1
if [ $? -eq 1 ]; then
	$WARNECHO "No entry found for passwordless sudo, changing /etc/sudoers..."
	echo $OSXROOTPASS > /dev/null 2>&1 | sudo -S bash -c "echo '%admin ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
	$OKECHO "User $OSXUSER added to sudoers, checking for CentOS ISO..."
else
	$OKECHO "User $OSXUSER already has passwordless sudo, checking for CentOS ISO..."
fi

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
	$WARNECHO "VirtualBox not found locally, checking for the latest version..."
else
	VBOXLOCALVERSION="$(vboxmanage --version)"
	VBOXLOCALVERSION="$(echo $VBOXLOCALVERSION | cut -d "r" -f 1)"
	$INFOECHO "VirtualBox local version $VBOXLOCALVERSION found, checking latest version..."
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
	$WARNECHO "Remote version $VBOXREMOTEVERSION is newer than local version $VBOXLOCALVERSION, checking for existing VMs...";

#	If VMs found, create backup first
VBOXDEFAULTVMPATH="$USERPATH/VirtualBox VMs"
VBOXFILESFOUND="${VBOXDEFAULTVMPATH}/*/*.vbox"
VBOXFILELIST="${TEMPDIR}/vboxbackup-list.txt"
find $VBOXDEFAULTVMPATH/ -name "*/*.vbox" >> $VBOXFILELIST


#	Create items list to be removed
	TEMPVBOXRAW="${TEMPDIR}/virtualboxitems-raw.txt"
	TEMPVBOXLIST="${TEMPDIR}/virtualboxitems-list.txt"
	mdfind -name "VirtualBox" > $TEMPVBOXRAW
	VBOXBACKUP="${USERPATH}/VirtualBox VMs"
	VBOXDELETEARRAY=(
		[0]="/Applications/VirtualBox.app"
		[1]="^/Library/Application\sSupport/VirtualBox"
		[2]="${USERPATH}/Library/LaunchAgents/org.virtualbox.vboxwebsrv.plist"
		[3]="${USERPATH}/Library/VirtualBox"
		[4]="/usr/local/bin/VirtualBox"
		)
	for i in "${VBOXDELETEARRAY[@]}"
	do
		grep $i $TEMPVBOXRAW -R | cut -d ":" -f 2 >> $TEMPVBOXLIST
	done
fi;


#	If version is older than latest, install latest

#	Remove temp dir & all contents
if [ -e $TEMPDIR ]; then
#	rm -rf $TEMPDIR
	$OKECHO "Test dir removed"
else
	$OKECHO "No temp dir found"
fi

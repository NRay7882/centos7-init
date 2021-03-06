#!/bin/bash

#< < < < < < < < C O N F I G U R E   P A R A M S   H E R E > > > > > > > > >
#	[PARAMS] Used for permissions, dir structure, and VM details (optional)
OSXROOTPASS=$1
OSXUSER="Macbook" && USERPATH="/Users/${OSXUSER}" #dev account, admin/root access
ISOPATH="${USERPATH}/sandbox/images/iso/CentOS-7-x86_64-Everything-1503-01.iso" #path to VM ISO
#VBOXNAME="pp-centos7-n01" #name for VirtualBox instance
#VMHOSTNAME="pp-centos7-n01.base" #hostname
#VMIPADDR="192.168.56.101" #VM virtual IP
#VMUSER="puppet" #user id for VM
#VMPASS="puppet" #user password for VM
#VMROOTPASS="puppet" #set VM root password
TODAYSDATE="$(date +%Y%m%d)"
DATESTAMP="$(date +%Y%m%d-$%H%M%S)"
RUNPATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
TEMPDIR="${RUNPATH}/temp"
VBOXFILELIST="${TEMPDIR}/vboxbackup-list.txt"
VBOXLOCALPATH="${USERPATH}/VirtualBox VMs"
#find $VBOXLOCALPATH/*/*.vbox >> $VBOXFILELIST
VMCOUNT="$(sudo cat $VBOXFILELIST | wc -l | sed -e 's/^[[:space:]]*//')"

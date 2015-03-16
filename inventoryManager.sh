#!/bin/sh

################################################################################
# Copyright (c) 2014 University of Utah Student Computing Labs.
# All Rights Reserved.
#
# Permission to use, copy, modify, and distribute this software and
# its documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice appears in all copies and
# that both that copyright notice and this permission notice appear
# in supporting documentation, and that the name of The University
# of Utah not be used in advertising or publicity pertaining to
# distribution of the software without specific, written prior
# permission. This software is supplied as is without expressed or
# implied warranties of any kind.
################################################################################

################################################################################
# inventory_manager.sh
#
# This script gathers machine-specific information for inventory purposes.
#
#
#	1.0.0	2014.11.14	Initial version. tjm
#	1.0.1	2015.01.22	Bug fixes, documentation tjm
#						changed fwpw detection method
#						preparation for github
#
#
################################################################################

################################################################################
# Things to do:
#
#
#
################################################################################

if /bin/test $(/usr/bin/id -u) -ne 0
then
	echo "Error: This script must be run as root."
	exit 1
fi

# Location of file containing "marketing" names
marketingData=/System/Library/PrivateFrameworks/ServerInformation.framework/Versions/A/Resources/English.lproj/SIMachineAttributes.plist

# Location of known inventory database.
# It uses the following CSV format:
# acquisition date, asset tag #, scan tag #, model name (unused), serial # (unused)
inventoryData=""

# Location of KeyAccess preferences file. Will use to add custom fields.
keyaccessPlist=/Library/Preferences/com.sassafras.KeyAccess.plist

# Set error condition flag.
dataError=false

# Get current date
rundate="$(/bin/date)"

# Get IP address of this machine.
runhost="$(/usr/sbin/system_profiler SPNetworkDataType | /usr/bin/grep -m1 "IPv4 Addresses" | /usr/bin/cut -d":" -f2 | /usr/bin/tr -d " ")"

# Email address for reports
mailto=""

# Location of temporary, curled HTML file
tempWarrantyPage=/tmp/appleWarrantyPage

# OS Version
osVersion="$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f2)"

# Find the model ID (ie "MacPro4,1")
modelID="$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep Ident | /usr/bin/cut -d":" -f2 | cut -d" " -f2)"
if /bin/test $? -ne 0
then
	modelID="_noModel_"
	dataError=true
fi

# Using model ID, find "marketing name" (ie "Mac Pro Early 2009")
# This info is not consistent within Apple itself and is used for informational purposes only.
marketingID="$(/usr/libexec/PlistBuddy -c "Print $modelID" $marketingData | /usr/bin/grep "marketing" | /usr/bin/cut -d"=" -f2 | /usr/bin/cut -d" " -f2-)"
if /bin/test $? -ne 0
then
	marketingID="_noMarket_"
	dataError=true
fi

# Find hardware serial number. This may be absent if hardware replaced and no serialized.
serialNumber="$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep "Serial Number (system)" | /usr/bin/cut -d":" -f2 | /usr/bin/cut -d" " -f2)"
if /bin/test $? -ne 0
then
	serialNumber="_noSerial_"
	dataError=true
fi

# Use serial number to cross reference inventory data.
dataLine="$(/usr/bin/grep $serialNumber $inventoryData)"
if /bin/test $? -ne 0
then
	aqDate="_noDate_"
	assetNumber="_noAsset_"
	scanNumber="_noScan_"
	dataError=true
else
	aqDate="$(echo "$dataLine" | /usr/bin/cut -d"," -f1)"
	assetNumber="$(echo "$dataLine" | /usr/bin/cut -d"," -f2)"
	scanNumber="$(echo "$dataLine" | /usr/bin/cut -d"," -f3)"
fi

# Use serial number to check Apple's warranty page
# Would like to use GSX instead, not sure if we'll be using this script long enough to justify the resource investment.
/usr/bin/curl -Lks -o $tempWarrantyPage "https://selfsolve.apple.com/wcResults.do?sn=$serial&Continue=Continue&num=0"

# Parse warranty page for AppleCare status.
appleCare="$(/usr/bin/grep "hwSupportHasCoverage" $tempWarrantyPage | /usr/bin/cut -d":" -f2 | /usr/bin/cut -d"," -f1 | /usr/bin/cut -b 5-9)"
if /bin/test "X$appleCare" = "X"
then
	appleCare="_ACareUndef_"
	dataError=true
fi

# Parse warranty page for Days since purchase info.
daysSincePurchase="$(/usr/bin/grep "numDaysSinceDOP" $tempWarrantyPage | /usr/bin/cut -d":" -f2 | /usr/bin/cut -d"," -f1 | /usr/bin/cut -d"'" -f2)"
if /bin/test "X$daysSincePurchase" = "X"
then
	daysSincePurchase="_DOPAgeUndef_"
	dataError=true
fi

# Check if firmware password is set.
# Does NOT check for nvram hash line! Only confirms a password is set or not.
# Apple changed management methods with 10.10, new tool.
if /bin/test $osVersion -eq 9
then
	/usr/local/bin/setregproptool -c
	if /bin/test $? -eq 0
	then
		firmWarePassword=true
	else
		firmWarePassword=false
	fi
elif /bin/test $osVersion -eq 10
then
	localFirmware=$(/usr/sbin/firmwarepasswd -check | /usr/bin/cut -d " " -f3)
	if [ "X$localFirmware" = "XYes"	]
	then
		firmWarePassword=true
	elif [ "X$localFirmware" = "XNo"	]
	then
		firmWarePassword=false
	else
		firmWarePassword="unknown"
		dataError=true
	fi
else
	firmWarePassword="unknown"
	dataError=true
fi


# Remove punctuation from marketing name. Special characters were causing issues.
cleanedMarketingID=$(echo $marketingID | /usr/bin/sed 's/\"/in/g' | /usr/bin/tr -d '().')
#cleanedMarketingID=$(echo $cleanedMarketingID | /usr/bin/tr -d '().')

# Populate custom fields in kayaccess preference file.
# 2 available fields left unused.
if /bin/test -f "$keyaccessPlist"
then
	/usr/bin/defaults write $keyaccessPlist assetCustom0 "$cleanedMarketingID"
	/usr/bin/defaults write $keyaccessPlist assetCustom1 "$serialNumber"
	/usr/bin/defaults write $keyaccessPlist assetCustom2 "$aqDate"
	/usr/bin/defaults write $keyaccessPlist assetCustom3 "$scanNumber"
	/usr/bin/defaults write $keyaccessPlist assetCustom4 "$assetNumber"
	/usr/bin/defaults write $keyaccessPlist assetCustom5 "$appleCare"
	/usr/bin/defaults write $keyaccessPlist assetCustom6 "$daysSincePurchase"
	#/usr/bin/defaults write $keyaccessPlist assetCustom7 "my_value"
	#/usr/bin/defaults write $keyaccessPlist assetCustom8 "my_value"
	/usr/bin/defaults write $keyaccessPlist assetCustom9 "$firmWarePassword"
fi

# Populate a line in nvram with same info.  For ARD, etc...
/usr/sbin/nvram scl-data-line="$cleanedMarketingID:$serialNumber:$aqDate:S$scanNumber:L$assetNumber:$appleCare:$daysSincePurchase:$firmWarePassword"

# If the error flag is flipped, generate an email.
# One monolithic error email is a bit vague, but sufficient.
if $dataError
then
#	echo "generate error"
	echo "$runhost $rundate There was an error running Inventory Manager. Missing and/or incorrect data. $cleanedMarketingID:$serialNumber:$aqDate:S$scanNumber:L$assetNumber:$appleCare:$daysSincePurchase:$firmWarePassword" | $(/usr/bin/mail -s "Inventory Manager Report - ERROR" "$mailto")
fi


exit 0

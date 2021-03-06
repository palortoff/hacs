#!/bin/bash
# check-xs1-sensors: Nagios/Icinga plugin to check the sensors of an EzControl XS1
# RF Controller
#
# Copyright (C) 2011 Daniel Kirstenpfad (https://github.com/bietiekay/hacs)
#
# This tool is part of the h.a.c.s. toolkit
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the 
# Free Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along with
# this program; if not, see <http://www.gnu.org/licenses/>.
#
# Requirements of this script:
# 	- wget
# 	- sed
#	- at least one EzControl XS1 device with firmware v3.0.0.2806 or newer
################################################################################

version_text="check-xs1-sensors Copyright (C) 2011 Daniel Kirstenpfad (https://github.com/bietiekay/hacs)"
usage_text="Usage: check-xs1-sensors -H <hostname> -U <username> -P <password> -S <sensor-id> -LL <lower-limit> -UL <upper-limit>"
help_text="Options:
  [-H <hostname>]
       hostname or IP of the EzControl XS1
  [-U <username> -P <password>]
  	   The username and password used to access the sensor / json interface
  	   of the EzControl XS1
  [-S <sensor id> <lower-limit> <upper-limit>]
	   The ID of the sensor of the EzControl XS1 - this is a number.
  [-Y <lower-limit>]
	   The lower limit which would be OK.
  [-X <upper-limit>]
	   The upper limit which would be OK."
while getopts "H:U:P:S:X:Y:h:V:?" option
do
	case $option in
		H)	XS1_HOST=$OPTARG;;
		U)	XS1_USER=$OPTARG;;
		P)	XS1_PASSWORD=$OPTARG;;
		S)	XS1_SENSORID=$OPTARG;;
		X)	XS1_UPPER_LIMIT=$OPTARG;;
		Y)	XS1_LOWER_LIMIT=$OPTARG;;
		h)	echo "$version_text"
			echo
			echo "$usage_text"
			echo
			echo "$help_text"
		  	exit 0;;
		V)	echo "$version_text"
		  	exit 0;;
		\?)	echo "$usage_text"
		  	exit 3;;
	esac
done

# run the command and check for limits...

export XS1_OUTPUT=`wget --http-user=$XS1_USER --http-password=$XS1_PASSWORD "http://"$XS1_HOST"/control?callback=sensor_config&cmd=get_state_sensor&number="$XS1_SENSORID -qO- | grep "value" | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/"value": //g' | sed 's/,//g' | sed 's/" "//g' | sed 's/\t//g'`

#  | sed 's/\./,/g'

# if there is no output return a warning
if [ "$XS1_OUTPUT" == "" ]; then
	echo "no output received from device";
	exit 2;
fi

if [ $(echo "if (${XS1_OUTPUT} < ${XS1_LOWER_LIMIT}) 1 else 0" | bc) -eq 1 ] ; then
	echo "value to low: "$XS1_OUTPUT;
	exit 1;
fi

if [ $(echo "if (${XS1_OUTPUT} > ${XS1_UPPER_LIMIT}) 1 else 0" | bc) -eq 1 ] ; then
        echo "value to high: "$XS1_OUTPUT;
        exit 2;
fi

echo $XS1_OUTPUT" OK"
exit 0


#!/bin/bash

# Parse RTC date into unixtime
rtcdate=$(hwclock -r)
# With coreutils date the conversion should be
unix_rtcdate=$(date -d "${rtcdate}" "+%s")

# Get current system unixtime
unix_systemdate=$(date "+%s")

# Only restore time if it's ahead of system time
if [ "${unix_rtcdate}" -gt "${unix_systemdate}" ]; then
   echo "Restoring system time from RTC"
   hwclock --hctosys
else
   echo "System time is ahead of RTC, writing to RTC and not restoring"
   hwclock -w
fi

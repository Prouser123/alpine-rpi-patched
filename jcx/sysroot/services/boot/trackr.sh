#!/bin/sh

chronyc_update() {
    chronyc makestep
    chronyc tracking
}

chronyc_check_tracking_status() {
    local status=$(chronyc tracking | grep -o 'Leap status.*' | cut -f2- -d ':' | cut -f2- -d ' ')
    echo "Chrony Leap Status: $status"
    if [ "$status" == "Normal" ]
    then
        echo "Found normal status! Let's force an update..."
        chronyc_update
    elif [ "$status" == "Not synchronised" ]
    then
        echo "Found not synhronised! let's wait..."
        sleep 2
        chronyc_check_tracking_status
    else
        echo "Found unknown status: '$status'"
        exit 1
    fi
}

chronyc_get_number_of_sources() {
    local num=$(chronyc sources | grep -o 'Number of sources.*' | cut -f5- -d ' ')
    echo "$num"
    # Eg output: "0", "2", etc
    if [ "$num" == "0" ]
    then
        echo "We have 0 sources! Waiting 2 seconds..."
        sleep 2
        chronyc_get_number_of_sources
    else
        echo "We have sources! Let's check our tracking status..."
        chronyc_check_tracking_status
    fi
}

chronyc_get_number_of_sources
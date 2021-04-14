#!/bin/sh

einfo "jcx-boot: trackr: Welcome!"

tbegin() {
    sbegin "trackr: $@"
}

wait_for_net() {
    if ping -q -c 1 -W 1 google.com > /dev/null; then
        # Network is up
        logr echo "We have a route to the internet!"
        "$@"
    else
        logr echo "No network, waiting 5 seconds..."
        sleep 5
        wait_for_net "$@"
    fi
}

chronyc_update() {
    logr chronyc makestep
    logr chronyc tracking
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

chronyc_quick() {
    tbegin "Configuring chrony for quick setup..."
    # Step 1: Inform chonry that we have a network connection
    logr chronyc online

    # Step 2: Tell chrony to make a set of measurements over a short period of time
    # (instead of the usual periodic ones)
    logr chronyc burst 4/4 #  4 good measurements, no more than 4 attempted connections

    # Step 3 (alt method instead of "sleep $X")
    logr chronyc waitsync 12 # Wait up to 12*10 seconds (120s // 2m) for chrony to sync to a source
    
    # TODO: Check waitsync exit code?

    tbegin "Waiting for chronyd to find sources"
    local num=$(chronyc sources | grep -o 'Number of sources.*' | cut -f5- -d ' ')
    einfo "jcx-boot: trackr: Found $num sources"
    # Eg output: "0", "2", etc
    if [ "$num" != "0" ]
    then
        # Continue
        chronyc_update
    fi
}

# /usr/bin/time -f %E <cmd>
# chronyc_get_number_of_sources

# Wait for net connection, then run chronyc_quick
wait_for_net chronyc_quick
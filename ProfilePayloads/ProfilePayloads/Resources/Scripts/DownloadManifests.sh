#!/bin/bash

#  DownloadManifests.sh
#  ProfilePayloads
#
#  Created by Erik Berglund.
#  Copyright © 2018 Erik Berglund. All rights reserved.

###
### VARIABLES
###

profileManifestsPath="$( /usr/bin/dirname "${SRCROOT}" )/ProfileManifests"

###
### FUNCTIONS
###

function gitPullProfileManifests {

    # Verify the ProfileManifests folder exists in the ProfilePayloads project
    if ! [[ -d ${profileManifestsPath} ]]; then return; fi

    # Run git pull to download the latest changes to the manifests.
    ( cd "${profileManifestsPath}" && git pull origin master )
}

###
### MAIN SCRIPT
###

gitPullProfileManifests

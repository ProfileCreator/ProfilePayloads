#!/bin/bash

#  CopyManifests.sh
#  ProfilePayloads
#
#  Created by Erik Berglund.
#  Copyright © 2018 Erik Berglund. All rights reserved.

###
### VARIABLES
###

profileManifestsPath="$( /usr/bin/dirname "${SRCROOT}" )/ProfileManifests/Manifests"
profilePayloadsBuildPath="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/Manifests"

###
### FUNCTIONS
###

function copyManifestsFromFolder {

    # Verify a folder name was passed to the function
    folderName="${1}"
    if [[ -z ${folderName} ]]; then return; fi

    # Verify the folder exists in the ProfileManifests project
    profileManifestsFolderPath="${profileManifestsPath}/${folderName}"
    if ! [[ -d ${profileManifestsFolderPath} ]]; then return; fi

    # Verify the folder exists in the ProfilePayloads build.
    # Create it if it doesn't exist
    profilePayloadsFolderPath="${profilePayloadsBuildPath}/${folderName}"
    if ! [[ -d ${profilePayloadsFolderPath} ]]; then
        if ! /bin/mkdir -p "${profilePayloadsFolderPath}"; then exit 1; fi
    fi

    # Copy each plist-file from the ProfileManifests project folder to the ProfilePayloads framework
    for manifest in "${profileManifestsFolderPath}"/*\.plist; do

        # Verify manifest validates
        if ! /usr/bin/plutil -lint "${manifest}"; then
            exit 1
        fi

        # Copy manifest
        /bin/cp "${manifest}" "${profilePayloadsFolderPath}"

        # Convert each mainfest plist-file to binary
        manifestName=$( basename "${manifest}" )
        /usr/bin/plutil -convert binary1 "${profilePayloadsFolderPath}/${manifestName}"
    done
}

function copyManifestIndex {

    # Verify a index exists at the expected location
    profileManifestsIndexPath="${profileManifestsPath}/index"
    if ! [[ -f ${profileManifestsIndexPath} ]]; then exit 1; fi

    if ! cp "${profileManifestsIndexPath}" "${profilePayloadsBuildPath}/index"; then exit 1; fi
}

###
### MAIN SCRIPT
###

copyManifestsFromFolder "ManagedPreferencesApple"
copyManifestsFromFolder "ManagedPreferencesApplications"
copyManifestsFromFolder "ManagedPreferencesDeveloper"
copyManifestsFromFolder "ManifestsApple"

#copyManifestIndex

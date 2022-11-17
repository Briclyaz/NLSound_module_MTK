#!/usr/bin/env bash

# Set full change log url
FULL_CHANGE_LOG="https://github.com/Briclyaz/NLSound_module_MTK_BETA/commits/main"

# Set a commit info
COMMIT_HEAD=$(git log --pretty=format:"%s")
COMMIT_AUTHOR=$(git log --pretty=format:"%an")

# Version code
CODE="v0.4"

# Version build (stable or beta)
Version="BETA"

# Version OTA
OTA="8"

#Module.prop
echo "id=NLSound
name=NLSound [MTK Devices]
version=$CODE $Version test-${build_number}
versionCode=$OTA
author=NLSound Team
description=This module globally improves audio quality when recording video/audio and listening to audio on your device.
support=https://t.me/nlsound_support" >> module.prop

# Set chips platform (Qualcomm/MTK)
PLATFORM="MTK"

# Zip name 
ZIPNAME=MTK_t${build_number}.zip

# Push zip in Telegram 
function push() {
curl -F document=@$1 "https://api.telegram.org/bot${token}/sendDocument" \
     -F chat_id="${chat_id}"  \
     -F "disable_web_page_preview=true" \
     -F "parse_mode=Markdown" \
     -F caption=" 
*Platform:* $PLATFORM  
*Version:* $Version  
*Full changelog:* [open]($FULL_CHANGE_LOG)  
*Commit author:* $COMMIT_AUTHOR
________________________
*Short list of changes:*
--- $COMMIT_HEAD ---" 
}

# Delete useless file
rm -rf *.zip
zip -r9 "${ZIPNAME}" . -x *build* -x *git* -x *README*
push "${ZIPNAME}"

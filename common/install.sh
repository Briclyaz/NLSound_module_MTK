#!/bin/bash

MODID="NLSound"

MIRRORDIR="/data/local/tmp/NLSound"

OTHERTMPDIR="/dev/NLSound"

patch_xml() {
  case "$2" in
    *mixer_paths*.xml) sed -i "\$apatch_xml $1 \$MODPATH$(echo $2 | sed "s|$MODPATH||") '$3' \"$4\"" $MODPATH/.aml.sh;;
    *) sed -i "\$apatch_xml $1 \$MODPATH$(echo $2 | sed "s|$MODPATH||") '$3' \"$4\"" $MODPATH/.aml.sh;;
  esac
  local NAME=$(echo "$3" | sed -r "s|^.*/.*\[@.*=\"(.*)\".*$|\1|")
  local NAMEC=$(echo "$3" | sed -r "s|^.*/.*\[@(.*)=\".*\".*$|\1|")
  local VAL=$(echo "$4" | sed "s|.*=||")
  [ "$(echo $4 | grep '=')" ] && local VALC=$(echo "$4" | sed "s|=.*||") || local VALC="value"
  case "$1" in
    "-d") xmlstarlet ed -L -d "$3" $2;;
    "-u") xmlstarlet ed -L -u "$3/@$VALC" -v "$VAL" $2;;
    "-s") if [ "$(xmlstarlet sel -t -m "$3" -c . $2)" ]; then
            xmlstarlet ed -L -u "$3/@$VALC" -v "$VAL" $2
          else
            local SNP=$(echo "$3" | sed "s|\[.*$||")
            local NP=$(dirname "$SNP")
            local SN=$(basename "$SNP")
            xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" -i "$SNP-$MODID" -t attr -n "$NAMEC" -v "$NAME" -i "$SNP-$MODID" -t attr -n "$VALC" -v "$VAL" -r "$SNP-$MODID" -v "$SN" $2
          fi;;
  esac
}

#author - Lord_Of_The_Lost@Telegram
memes_confxml() {
case $FILE in
*.conf) sed -i "/$1 {/,/}/d" $FILE
sed -i "/$2 {/,/}/d" $FILE
sed -i "s/^effects {/effects {\n  $1 {\nlibrary $2\nuuid $5\n  }/g" $FILE
sed -i "s/^libraries {/libraries {\n  $2 {\npath $3\/$4\n  }/g" $FILE;;
*.xml) sed -i "/$1/d" $FILE
sed -i "/$2/d" $FILE
sed -i "/<libraries>/ a\<library name=\"$2\" path=\"$4\"\/>" $FILE
sed -i "/<effects>/ a\<effect name=\"$1\" library=\"$2\" uuid=\"$5\"\/>" $FILE;;
esac
}

libs_checker(){
ASDK="$(GREP_PROP "ro.build.version.sdk")"
DYNLIB=true
[ $ASDK -lt 26 ] && DYNLIB=false
[ -z $DYNLIB ] && DYNLIB=false
if $DYNLIB; then 
DYNLIBPATCH="\/vendor"; 
else 
DYNLIBPATCH="\/system"; 
fi
}

altmemes_confxml() {
case $1 in
*.conf) local SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *music {/p}" $1 | sed -r "s/( *).*/\1/")
local EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\music {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
for EFFECT in $EFFECTS; do
local SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
[ "$EFFECT" != "atmos" ] && sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/ s/^/#/g}" $1
done;;
*.xml) local EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"music\">$/,/^ *<\/stream>$/ {/<stream type=\"music\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
for EFFECT in $EFFECTS; do
[ "$EFFECT" != "atmos" ] && sed -ri "s/^( *)<apply effect=\"$EFFECT\"\/>/\1<\!--<apply effect=\"$EFFECT\"\/>-->/" $1
done;;
esac
}

#author - Lord_Of_The_Lost@Telegram
effects_patching() {
case $1 in
-pre) CONF=pre_processing; XML=preprocess;;
-post) CONF=output_session_processing; XML=postprocess;;
esac
case $2 in
*.conf) if [ ! "$(sed -n "/^$CONF {/,/^}/p" $2)" ]; then
echo -e "\n$CONF {\n$3 {\n$4 {\n}\n}\n}" >> $2
elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^}/p}" $2)" ]; then
sed -i "/^$CONF {/,/^}/ s/$CONF {/$CONF {\n$3 {\n$4 {\n}\n}/" $2
elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^}/ {/$4 {/,/}/p}}" $2)" ]; then
sed -i "/^$CONF {/,/^}/ {/$3 {/,/^}/ s/$3 {/$3 {\n$4 {\n}/}" $2
fi;;
*.xml) if [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/p" $2)" ]; then 
sed -i "/<\/audio_effects_conf>/i\<$XML>\n   <stream type=\"$3\">\n<apply effect=\"$4\"\/>\n<\/stream>\n<\/$XML>" $2
elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/p}" $2)" ]; then 
sed -i "/^ *<$XML>/,/^ *<\/$XML>/ s/<$XML>/<$XML>\n<stream type=\"$3\">\n<apply effect=\"$4\"\/>\n<\/stream>/" $2
elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ {/^ *<apply effect=\"$4\"\/>/p}}" $2)" ]; then
sed -i "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ s/<stream type=\"$3\">/<stream type=\"$3\">\n<apply effect=\"$4\"\/>/}" $2
fi;;
esac
}

[ -f /system/vendor/build.prop ] && BUILDS="/system/build.prop /system/vendor/build.prop" || BUILDS="/system/build.prop"

MTKG90T=$(grep "ro.board.platform=mt6785" $BUILDS)
HELIOG85=$(grep "ro.board.platform=mt6768" $BUILDS)
MT6875=$(grep "ro.board.platform=mt6873" $BUILDS)
RN8PRO=$(grep -E "ro.product.vendor.device=begonia.*|ro.product.vendor.device=begonianin.*" $BUILDS)
R10X4GNOTE9=$(grep -E "ro.product.vendor.device=merlin.*" $BUILDS)
R10XPRO5G=$(grep -E "ro.product.vendor.device=bomb.*" $BUILDS)
R10X5G=$(grep -E "ro.product.vendor.device=atom.*" $BUILDS)

APOS="$(find /system /vendor /system_ext /product -type f -name "*AudioParamOptions.xml")"
ADEVS="$(find /system /vendor /system_ext /product -type f -name "*audio_device.xml")"
AUEMS="$(find /system /vendor /system_ext /product -type f -name "*audio_em.xml")"
AURCONFS="$(find /system /vendor /system_ext /product -type f -name "*aurisys_config.xml")"
AURCONFHIFIS="$(find /system /vendor /system_ext /product -type f -name "*aurisys_config.xml")"
MCODECS="$(find /system /vendor /system_ext /product -type f -name "media_codecs_*_audio.xml")"
DSMS="$(find /system /vendor /system_ext /product -type f -name "DSM.xml")"
DSMCONFIGS="$(find /system /vendor /system_ext /product -type f -name "DSM_config.xml")"
APAROPTS="$(find /system /vendor /system_ext /product -type f -name "AudioParamOptions.xml")"

VNDK=$(find /system/lib /vendor/lib -type d -iname "*vndk*")
VNDK64=$(find /system/lib64 /vendor/lib64 -type d -iname "*vndk*")
VNDKQ=$(find /system/lib /vendor/lib -type d -iname "vndk*-Q")

SETTINGS=$MODPATH/settings.nls

RESTORE=false

STEP1=false
STEP2=false
STEP3=false
STEP4=false
STEP5=false
STEP6=false
STEP7=false
STEP8=false
STEP9=false
STEP10=false
STEP11=false
STEP12=false
STEP13=false
STEP14=false
STEP15=false
STEP16=false
STEP17=false
STEP18=false
STEP19=false
STEP20=false

mkdir -p $MODPATH/tools
cp_ch $MODPATH/common/addon/External-Tools/tools/$ARCH32/* $MODPATH/tools/

ui_print " - Configurate me, pls >.< -"
ui_print " "
ui_print "***************************************************"
ui_print "* [1/12]                                          *"
ui_print "*                                                 *"
ui_print "*           • This option configure •             *"
ui_print "*            your interal audio codec             *"
ui_print "*       of this option may cause no sound!        *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP1=true
sed -i 's/STEP1=false/STEP1=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [2/12]                                          *"
ui_print "*                                                 *"
ui_print "*           • This option configure •             *"
ui_print "*            your interal audio codec             *"
ui_print "*       of this option may cause no sound!        *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP2=true
sed -i 's/STEP2=false/STEP2=true/g' $SETTINGS
fi


ui_print " "
ui_print "***************************************************"
ui_print "* [3/12]                                          *"
ui_print "*                                                 *"
ui_print "*      • This option applies new perameters •     *"
ui_print "*           to your device's audio codec.         *"
ui_print "*                 May cause problems.             *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP3=true
sed -i 's/STEP3=false/STEP3=true/g' $SETTINGS
fi


ui_print " "
ui_print "***************************************************"
ui_print "* [4/12]                                          *"
ui_print "*                                                 *"
ui_print "*   • This option configure MediaTek Bessound •   *"
ui_print "*            technology in your device.           *"
ui_print "*                May cause problems.              *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP4=true
sed -i 's/STEP4=false/STEP4=true/g' $SETTINGS
fi


ui_print " "
ui_print "***************************************************"
ui_print "* [5/12]                                          *"
ui_print "*                                                 *"
ui_print "*       • This step will do the following •       *"
ui_print "*        - Unlocks the sampling frequency         *"
ui_print "*          of the audio up to 384000 kHz;         *"
ui_print "*        - Enable the AAC codec switch in         *"
ui_print "*          the Bluetooth headphone settings;      *"
ui_print "*        - Enable additional support for          *"
ui_print "*          IIR parameters;                        *"
ui_print "*        - Enable support for stereo recording;   *"
ui_print "*        - Enable support for hd voice            *"
ui_print "*          recording quality;                     *"
ui_print "*        - Enable Dolby and Hi-Fi support         *"
ui_print "*          (on some devices);                     *"
ui_print "*        - Enable audio focus support             *"
ui_print "*          during video recording;                *"
ui_print "*        - Enable support for quick connection    *"
ui_print "*          of Bluetooth headphones.               *"
ui_print "*                                                 *"
ui_print "*  And much more . . .                            *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP5=true
sed -i 's/STEP5=false/STEP5=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [6/12]                                          *"
ui_print "*                                                 *"
ui_print "*      • This step improve audio parameters •     *"
ui_print "*           in your internal audio codec.         *"
ui_print "*                May case problem.                *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP6=true
sed -i 's/STEP6=false/STEP6=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [7/12]                                          *"
ui_print "*                                                 *"
ui_print "*    • This option configure DSP HAL libs •       *"
ui_print "*          technology in your device.             *"
ui_print "*              May cause problems.                *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP7=true
sed -i 's/STEP7=false/STEP7=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [8/12]                                          *"
ui_print "*                                                 *"
ui_print "*      • This step patching media codecs •        *"
ui_print "*     in your system for improving quality.       *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP8=true
sed -i 's/STEP8=false/STEP8=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [9/12]                                          *"
ui_print "*                                                 *"
ui_print "*      • This step patching DSM files •           *"
ui_print "*     in your system for improving quality.       *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP9=true
sed -i 's/STEP9=false/STEP9=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [10/12]                                         *"
ui_print "*                                                 *"
ui_print "*  • This step added new Dirac in your system •   *"
ui_print "*             May cause problems.                 *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP10=true
sed -i 's/STEP10=false/STEP10=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [11/12]                                         *"
ui_print "*                                                 *"
ui_print "*  • This option will change the sound quality •  *"
ui_print "*                  the most.                      *"
ui_print "*             May cause problems.                 *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP11=true
sed -i 's/STEP11=false/STEP11=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [12/12]                                         *"
ui_print "*                                                 *"
ui_print "* • This option will improve the audio quality •  *"
ui_print "*    in Bluetooth, as well as fix the problem     *"
ui_print "*      of disappearing the AAC codec switch       *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP12=true
sed -i 's/STEP12=false/STEP12=true/g' $SETTINGS
fi


ui_print " "
ui_print " - Processing. . . -"
ui_print " "
ui_print " - You can minimize Magisk and use the device normally -"
ui_print " - and then come back here to reboot and apply the changes. -"
ui_print " "

if [ "$STEP1" == "true" ]; then
for OAPO in ${APOS}; do
APO="$MODPATH$(echo $OAPO | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAPO $APO
sed -i 's/\t/  /g' $APO
if [ "$RN8PRO" ]; then
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_VOIP_ENHANCEMENT_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_ASR_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_VOICE_UNLOCK_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HAC_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HEADSET_ACTIVE_NOISE_CANCELLATION"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_AUDIO_TUNING_TOOL_VERSION"]' "V5"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HIFIAUDIO_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_A2DP_OFFLOAD_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="VIR_ASR_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="VIR_VOICE_UNLOCK_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_IIR_MIC_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_FIR_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_FIR_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_BESLOUDNESS_SUPPORT"]' "yes"
fi
if [ "$R10X4GNOTE9" ]; then
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_VOIP_ENHANCEMENT_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_ASR_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_VOICE_UNLOCK_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HAC_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HEADSET_ACTIVE_NOISE_CANCELLATION"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_AUDIO_TUNING_TOOL_VERSION"]' "V5"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HIFIAUDIO_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_A2DP_OFFLOAD_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="VIR_ASR_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="VIR_VOICE_UNLOCK_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_IIR_MIC_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_FIR_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_FIR_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_BESLOUDNESS_SUPPORT"]' "yes"
fi
if [ "$R10XPRO5G" ]; then
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_VOIP_ENHANCEMENT_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_ASR_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_VOICE_UNLOCK_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HAC_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HEADSET_ACTIVE_NOISE_CANCELLATION"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_AUDIO_TUNING_TOOL_VERSION"]' "V5"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HIFIAUDIO_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_A2DP_OFFLOAD_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="VIR_ASR_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="VIR_VOICE_UNLOCK_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_IIR_MIC_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_FIR_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_FIR_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_BESLOUDNESS_SUPPORT"]' "yes"
fi
if [ "$R10X5G" ]; then
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_VOIP_ENHANCEMENT_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_ASR_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_VOICE_UNLOCK_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HAC_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HEADSET_ACTIVE_NOISE_CANCELLATION"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_AUDIO_TUNING_TOOL_VERSION"]' "V5"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_HIFIAUDIO_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_A2DP_OFFLOAD_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="VIR_ASR_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="VIR_VOICE_UNLOCK_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_IIR_MIC_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_FIR_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_FIR_IIR_ENH_SUPPORT"]' "yes"
patch_xml -u $APO '/AudioParamOptions/Param[@name="MTK_BESLOUDNESS_SUPPORT"]' "yes"
fi
done
fi

if [ "$STEP2" == "true" ]; then
for OADEV in ${ADEVS}; do
ADEV="$MODPATH$(echo $OADEV | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OADEV $ADEV
sed -i 's/\t/  /g' $ADEV
if [ "$RN8PRO" ]; then
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Speaker_class_Switch"]' "CLASSH"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Debug_Setting"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Codec_Debug_Setting"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Ext_Speaker_Amp_Switch"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/path[@name="ext_speaker_output"]/kctl[@name="Ext_Speaker_Amp_Switch"]' "1"
fi
if [ "$R10X4GNOTE9" ]; then
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Speaker_class_Switch"]' "CLASSH"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Debug_Setting"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Codec_Debug_Setting"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Ext_Speaker_Amp_Switch"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/path[@name="ext_speaker_output"]/kctl[@name="Ext_Speaker_Amp_Switch"]' "1"
fi
if [ "$R10XPRO5G" ]; then
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Speaker_class_Switch"]' "CLASSH"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Debug_Setting"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Codec_Debug_Setting"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Ext_Speaker_Amp_Switch"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/path[@name="ext_speaker_output"]/kctl[@name="Ext_Speaker_Amp_Switch"]' "1"
fi
if [ "$R10X5G" ]; then
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Speaker_class_Switch"]' "CLASSH"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Debug_Setting"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Codec_Debug_Setting"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Ext_Speaker_Amp_Switch"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/path[@name="ext_speaker_output"]/kctl[@name="Ext_Speaker_Amp_Switch"]' "1"
fi
done
fi

if [ "$STEP3" == "true" ]; then
for OAUEM in ${AUEMS}; do
AUEM="$MODPATH$(echo $OAUEM | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAUEM $AUEM
sed -i 's/\t/  /g' $AUEM
if [ "$RN8PRO" ]; then
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="TDM_Record"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="SET_MODE"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="HAHA"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="Set_SpeechCall_DL_Mute"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="SetFmVolume"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="ANC_CMD"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="dumplog"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="LowLatencyDebugEnable"]' "1"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="DetectPulseEnable"]' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.track.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.drc.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.offload.write.raw"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.resampler.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.end.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.record.dump.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.effect.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.aaudio.pcm"]/check' "1"
fi
if [ "$R10X4GNOTE9" ]; then
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="TDM_Record"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="SET_MODE"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="HAHA"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="Set_SpeechCall_DL_Mute"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="SetFmVolume"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="ANC_CMD"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="dumplog"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="LowLatencyDebugEnable"]' "1"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="DetectPulseEnable"]' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.track.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.drc.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.offload.write.raw"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.resampler.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.end.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.record.dump.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.effect.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.aaudio.pcm"]/check' "1"
fi
if [ "$R10XPRO5G" ]; then
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="TDM_Record"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="SET_MODE"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="HAHA"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="Set_SpeechCall_DL_Mute"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="SetFmVolume"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="ANC_CMD"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="dumplog"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="LowLatencyDebugEnable"]' "1"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="DetectPulseEnable"]' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.track.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.drc.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.offload.write.raw"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.resampler.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.end.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.record.dump.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.effect.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.aaudio.pcm"]/check' "1"
fi
if [ "$R10X5G" ]; then
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="TDM_Record"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="SET_MODE"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="HAHA"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="Set_SpeechCall_DL_Mute"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="SetFmVolume"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="ANC_CMD"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="dumplog"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="LowLatencyDebugEnable"]' "1"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="DetectPulseEnable"]' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.track.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.drc.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.offload.write.raw"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.resampler.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.mixer.end.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.record.dump.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.af.effect.pcm"]/check' "1"
patch_xml -u $AUEM '/AudioParameter/DumpOptions/Category[@name="AudioMixer"]/option [@name="SetParameters"]/cmd[@name="vendor.aaudio.pcm"]/check' "1"
fi
done
fi

if [ "$STEP4" == "true" ]; then
for OAURCONF in ${AURCONFS}; do
AURCONF="$MODPATH$(echo $OAURCONF | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAURCONF $AURCONF
sed -i 's/\t/  /g' $AURCONF
if [ "$RN8PRO" ]; then
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
fi
if [ "$R10X4GNOTE9" ]; then
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
fi
if [ "$R10XPRO5G" ]; then
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
fi
if [ "$R10X5G" ]; then
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
fi
done
fi

if [ "$STEP5" == "true" ]; then
for ODEVFEA in ${DEVFEAS}; do 
DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$ODEVFEA $DEVFEA
sed -i 's/\t/  /g' $DEVFEA
patch_xml -s $DEVFEA '/features/bool[@name="support_a2dp_latency"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_48000"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_96000"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_192000"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_low_latency"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_mid_latency"]' "false"
patch_xml -s $DEVFEA '/features/bool[@name="support_high_latency"]' "false"
patch_xml -s $DEVFEA '/features/bool[@name="support_interview_record_param"]' "false"
done
fi

#audio parameters
if [ "$STEP6" == "true" ]; then
for OAPAROPTS in ${APAROPTS}; do 
APAR="$MODPATH$(echo $OAPAROPTS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAPAROPTS $APAR
sed -i 's/\t/  /g' $APAR
sed -i 's/Param name="MTK_WB_SPEECH_SUPPORT" value=".*"/Param name="MTK_WB_SPEECH_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_HD_REC_SUPPORT" value=".*"/Param name="MTK_WB_MTK_AUDIO_HD_REC_SUPPORTSPEECH_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_DUAL_MIC_SUPPORT" value=".*"/Param name="MTK_DUAL_MIC_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_HANDSFREE_DMNR_SUPPORT" value=".*"/Param name="MTK_HANDSFREE_DMNR_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="DMNR_TUNNING_AT_MODEMSIDE" value=".*"/Param name="DMNR_TUNNING_AT_MODEMSIDE" value=""/g' $APAR
sed -i 's/Param name="MTK_VOIP_ENHANCEMENT_SUPPORT" value=".*"/Param name="MTK_VOIP_ENHANCEMENT_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_TB_WIFI_3G_MODE" value=".*"/Param name="MTK_TB_WIFI_3G_MODE" value=""/g' $APAR
sed -i 's/Param name="MTK_DISABLE_EARPIECE" value=".*"/Param name="MTK_DISABLE_EARPIECE" value=""/g' $APAR
sed -i 's/Param name="MTK_ASR_SUPPORT" value=".*"/Param name="MTK_ASR_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_VOIP_NORMAL_DMNR" value=".*"/Param name="MTK_VOIP_NORMAL_DMNR" value="no"/g' $APAR
sed -i 's/Param name="MTK_VOIP_HANDSFREE_DMNR" value=".*"/Param name="MTK_VOIP_HANDSFREE_DMNR" value="no"/g' $APAR
sed -i 's/Param name="MTK_INCALL_NORMAL_DMNR" value=".*"/Param name="MTK_INCALL_NORMAL_DMNR" value="yes"/g' $APAR
sed -i 's/Param name="MTK_VOICE_UNLOCK_SUPPORT" value=".*"/Param name="MTK_VOICE_UNLOCK_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_VOICE_UI_SUPPORT" value=".*"/Param name="MTK_VOICE_UI_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_ACF_AUTO_GEN_SUPPORT" value=".*"/Param name="MTK_ACF_AUTO_GEN_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_SPEAKER_MONITOR_SUPPORT" value=".*"/Param name="MTK_SPEAKER_MONITOR_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_AUDIO_BLOUD_CUSTOMPARAMETER_REV" value=".*"/Param name="MTK_AUDIO_BLOUD_CUSTOMPARAMETER_REV" value=""/g' $APAR
sed -i 's/Param name="MTK_MAGICONFERENCE_SUPPORT" value=".*"/Param name="MTK_MAGICONFERENCE_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_HAC_SUPPORT" value=".*"/Param name="MTK_HAC_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_SPH_LPBK_PARAM" value=".*"/Param name="MTK_AUDIO_SPH_LPBK_PARAM" value=""/g' $APAR
sed -i 's/Param name="MTK_AUDIO_GAIN_TABLE_BT" value=".*"/Param name="MTK_AUDIO_GAIN_TABLE_BT" value=""/g' $APAR
sed -i 's/Param name="MTK_AUDIO_BT_NREC_WO_ENH_MODE" value=".*"/Param name="MTK_AUDIO_BT_NREC_WO_ENH_MODE" value=""/g' $APAR
sed -i 's/Param name="MTK_AUDIO_TUNING_TOOL_V2_PHASE" value=".*"/Param name="MTK_AUDIO_TUNING_TOOL_V2_PHASE" value="2"/g' $APAR
sed -i 's/Param name="MATV_AUDIO_SUPPORT" value=".*"/Param name="MATV_AUDIO_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_FM_SUPPORT" value=".*"/Param name="MTK_FM_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_HEADSET_ACTIVE_NOISE_CANCELLATION" value=".*"/Param name="MTK_HEADSET_ACTIVE_NOISE_CANCELLATION" value=""/g' $APAR
sed -i 's/Param name="MTK_WB_SPEECH_SUPMTK_SUPPORT_TC1_TUNNINGPORT" value=".*"/Param name="MTK_WB_SPEECH_SUPMTK_SUPPORT_TC1_TUNNINGPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_AUDIO_SPEAKER_PATH" value=".*"/Param name="MTK_AUDIO_SPEAKER_PATH" value="smartpa_nxp_tfa9874"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_NUMBER_OF_MIC" value=".*"/Param name="MTK_AUDIO_NUMBER_OF_MIC" value="2"/g' $APAR
sed -i 's/Param name="MTK_AURISYS_FRAMEWORK_SUPPORT" value=".*"/Param name="MTK_AURISYS_FRAMEWORK_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_BESLOUDNESS_RUN_WITH_HAL" value=".*"/Param name="MTK_BESLOUDNESS_RUN_WITH_HAL" value="yes"/g' $APAR
sed -i 's/Param name="MTK_AUDIO" value=".*"/Param name="MTK_AUDIO" value="yes"/g' $APAR
sed -i 's/Param name="USE_CUSTOM_AUDIO_POLICY" value=".*"/Param name="USE_CUSTOM_AUDIO_POLICY" value=""/g' $APAR
sed -i 's/Param name="USE_XML_AUDIO_POLICY_CONF" value=".*"/Param name="USE_XML_AUDIO_POLICY_CONF" value="1"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_TUNING_TOOL_VERSION" value=".*"/Param name="MTK_AUDIO_TUNING_TOOL_VERSION" value="V2.2"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_TUNNELING_SUPPORT" value=".*"/Param name="MTK_AUDIO_TUNNELING_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_SMARTPA_DUMMY_LIB" value=".*"/Param name="MTK_SMARTPA_DUMMY_LIB" value=""/g' $APAR
sed -i 's/Param name="MTK_HIFIAUDIO_SUPPORT" value=".*"/Param name="MTK_HIFIAUDIO_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_BESLOUDNESS_SUPPORT" value=".*"/Param name="MTK_BESLOUDNESS_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_USB_PHONECALL" value=".*"/Param name="MTK_USB_PHONECALL" value="AP"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_NUMBER_OF_SPEAKER" value=".*"/Param name="MTK_AUDIO_NUMBER_OF_SPEAKER" value="1"/g' $APAR
sed -i 's/Param name="MTK_A2DP_OFFLOAD_SUPPORT" value=".*"/Param name="MTK_A2DP_OFFLOAD_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_TTY_SUPPORT" value=".*"/Param name="v" value="yes"/g' $APAR
sed -i 's/Param name="VIR_WIFI_ONLY_SUPPORT" value=".*"/Param name="VIR_WIFI_ONLY_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_3G_DATA_ONLY_SUPPORT" value=".*"/Param name="VIR_3G_DATA_ONLY_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_ASR_SUPPORT" value=".*"/Param name="VIR_ASR_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_VOIP_NORMAL_DMNR_SUPPORT" value=".*"/Param name="VIR_VOIP_NORMAL_DMNR_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_VOIP_HANDSFREE_DMNR_SUPPORT" value=".*"/Param name="VIR_VOIP_HANDSFREE_DMNR_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_NO_SPEECH" value=".*"/Param name="VIR_NO_SPEECH" value="no"/g' $APAR
sed -i 's/Param name="VIR_INCALL_NORMAL_DMNR_SUPPORT" value=".*"/Param name="VIR_INCALL_NORMAL_DMNR_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="VIR_INCALL_HANDSFREE_DMNR_SUPPORT" value=".*"/Param name="VIR_INCALL_HANDSFREE_DMNR_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_VOICE_UNLOCK_SUPPORT" value=".*"/Param name="VIR_VOICE_UNLOCK_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V5" value=".*"/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V5" value="yes"/g' $APAR
sed -i 's/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V4" value=".*"/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V4" value="no"/g' $APAR
sed -i 's/Param name="VIR_MAGI_CONFERENCE_SUPPORT" value=".*"/Param name="VIR_MAGI_CONFERENCE_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_HIERARCHICAL_PARAM_SUPPORT" value=".*"/Param name="MTK_AUDIO_HIERARCHICAL_PARAM_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_TUNING_TOOL_V2_PHASE" value=".*"/Param name="MTK_AUDIO_TUNING_TOOL_V2_PHASE" value="yes"/g' $APAR
sed -i 's/Param name="VIR_MTK_VOIP_IIR_ENH_SUPPORT" value=".*"/Param name="VIR_MTK_VOIP_IIR_ENH_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="VIR_MTK_VOIP_IIR_MIC_SUPPORT" value=".*"/Param name="VIR_MTK_VOIP_IIR_MIC_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="5_POLE_HS_SUPPORT" value=".*"/Param name="5_POLE_HS_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="VIR_MTK_USB_PHONECALL" value=".*"/Param name="VIR_MTK_USB_PHONECALL" value="yes"/g' $APAR
sed -i 's/Param name="SPK_PATH_NO_ANA" value=".*"/Param name="SPK_PATH_NO_ANA" value="yes"/g' $APAR
sed -i 's/Param name="RCV_PATH_INT" value=".*"/Param name="RCV_PATH_INT" value="yes"/g' $APAR
sed -i 's/Param name="SPH_PARAM_VERSION" value=".*"/Param name="SPH_PARAM_VERSION" value="3.0"/g' $APAR
sed -i 's/Param name="SPH_PARAM_TTY" value=".*"/Param name="SPH_PARAM_TTY" value="yes"/g' $APAR
sed -i 's/Param name="FIX_WB_ENH" value=".*"/Param name="FIX_WB_ENH" value="yes"/g' $APAR
sed -i 's/Param name="MTK_IIR_ENH_SUPPORT" value=".*"/Param name="MTK_IIR_MIC_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_IIR_MIC_SUPPORT" value=".*"/Param name="MTK_IIR_MIC_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_FIR_IIR_ENH_SUPPORT" value=".*"/Param name="MTK_FIR_IIR_ENH_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="SPH_PARAM_SV" value=".*"/Param name="SPH_PARAM_SV" value="yes"/g' $APAR
sed -i 's/Param name="VIR_SCENE_CUSTOMIZATION_SUPPORT" value=".*"/Param name="VIR_SCENE_CUSTOMIZATION_SUPPORT" value="yes"/g' $APAR
done
fi

if [ "$STEP7" == "true" ]; then
for OAURCONFHIFI in ${AURCONFHIFIS}; do 
AURCONFHIFI="$MODPATH$(echo $OAURCONFHIFI | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAURCONFHIFI $AURCONFHIFI
sed -i 's/\t/  /g' $AURCONFHIFI
if [ "$RN8PRO" ]; then
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_bessound"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_bessound"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="smartpa_tfaxxxx"]/components/component[@name="sample_rate"]' "48000,96000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="smartpa_tfaxxxx"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_dcrflt"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
fi
if [ "$R10X4GNOTE9" ]; then
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_bessound"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_bessound"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="smartpa_tfaxxxx"]/components/component[@name="sample_rate"]' "48000,96000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="smartpa_tfaxxxx"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_dcrflt"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
fi
if [ "$R10X4GNOTE9" ]; then
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_bessound"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_bessound"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="smartpa_tfaxxxx"]/components/component[@name="sample_rate"]' "48000,96000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="smartpa_tfaxxxx"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_dcrflt"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
fi
if [ "$R10X5G" ]; then
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_bessound"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_bessound"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="smartpa_tfaxxxx"]/components/component[@name="sample_rate"]' "48000,96000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="smartpa_tfaxxxx"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="mtk_dcrflt"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONFHIFI '/aurisys_config/hal_librarys/library[@name="aurisys_demo"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
fi
done
fi

#mcodecs
if [ "$STEP8" == "true" ]; then
for OMCODECS in ${MCODECS}; do
MEDIACODECS="$MODPATH$(echo $OMCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OMCODECS $MEDIACODECS
sed -i 's/\t/  /g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="8000,11025,12000,16000,22050,24000,32000,44100,48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="32000,44100,48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="7350,8000,11025,12000,16000,22050,24000,32000,44100,48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="8000-48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="8000-96000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="8000-192000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="bitrate-modes" value="CBR"/name="bitrate-modes" value="CQ"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-10"  default="9"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-10"  default="8"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-10"  default="7"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-10"  default="6"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-8"  default="7"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-8"  default="6"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-8"  default="5"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-8"  default="4"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="quality" range="0-80"  default="100"/name="quality" range="0-100"  default="100"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="8000-320000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="8000-960000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="32000-500000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="6000-510000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="1-10000000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="500-512000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="32000-640000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="32000-6144000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="16000-2688000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="64000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
done
fi

if [ "$STEP9" == "true" ]; then
#dsm
for ODSMS in ${DSMS}; do
DSM="$MODPATH$(echo $ODSMS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$ODSMS $DSM
sed -i 's/\t/  /g' $DSM
sed -i 's/params type="*"/params type="float"/g' $DSM
sed -i 's/currentv="*"/currentv="123.000000"/g' $DSM
done
fi



if [ "$STEP10" == "true" ]; then
for OFILE in ${AECFGS}; do
FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OFILE $FILE
sed -i 's/\t/  /g' $FILE
altmemes_confxml $FILE
memes_confxml "dirac_gef" "dirac_gef" "$DYNLIBPATCH\/lib\/soundfx" "libdiraceffect.so" "3799d6d1-22c5-43c3-b3ec-d664cf8d2f0d"
effects_patching -post "$FILE" "music" "dirac_gef"
done

mkdir -p $MODPATH/system/vendor/etc/dirac $MODPATH/system/vendor/lib/rfsa/adsp $MODPATH/system/vendor/lib/soundfx
cp_ch $NEWdirac/diracvdd.bin $MODPATH/system/vendor/etc/
cp_ch $NEWdirac/interfacedb $MODPATH/system/vendor/etc/dirac
cp_ch $NEWdirac/dirac_resource.dar $MODPATH/system/vendor/lib/rfsa/adsp
cp_ch $NEWdirac/dirac.so $MODPATH/system/vendor/lib/rfsa/adsp
cp_ch $NEWdirac/libdirac-capiv2.so $MODPATH/system/vendor/lib/rfsa/adsp
cp_ch $NEWdirac/libdiraceffect.so $MODPATH/system/vendor/lib/soundfx

echo -e '\n# Patch dirac
persist.dirac.acs.controller=gef
persist.dirac.gef.oppo.syss=true
persist.dirac.config=64
persist.dirac.gef.exs.did=50,50
persist.dirac.gef.ext.did=750,750,750,750
persist.dirac.gef.ins.did=50,50,50
persist.dirac.gef.int.did=750,750,750,750
persist.dirac.gef.ext.appt=0x00011130,0x00011134,0x00011136
persist.dirac.gef.exs.appt=0x00011130,0x00011131
persist.dirac.gef.int.appt=0x00011130,0x00011134,0x00011136
persist.dirac.gef.ins.appt=0x00011130,0x00011131
persist.dirac.gef.exs.mid=268512739
persist.dirac.gef.ext.mid=268512737
persist.dirac.gef.ins.mid=268512738
persist.dirac.gef.int.mid=268512736
persist.dirac.path=/vendor/etc/dirac
ro.dirac.acs.storeSettings=1
persist.dirac.acs.ignore_error=1
ro.audio.soundfx.dirac=true
ro.vendor.audio.soundfx.type=dirac
persist.audio.dirac.speaker=true
persist.audio.dirac.eq=5.0,4.0,3.0,3.0,4.0,1.0,0.0
persist.audio.dirac.headset=1
persist.audio.dirac.music.state=1' >> $MODPATH/system.prop
fi

if [ "$STEP11" == "true" ]; then
echo -e "\n#
ro.mediacodec.min_sample_rate=7350
ro.mediacodec.max_sample_rate=2822400
vendor.audio.tunnel.encode=true
tunnel.audio.encode=true
qc.tunnel.audio.encode=true
mpq.audio.decode=true
audio.nat.codec.enabled=1
audio.decoder_override_check=true

vendor.audio.aac.complexity.default=10
vendor.audio.aac.quality=100
vendor.audio.vorbis.complexity.default=10
vendor.audio.vorbis.quality=100
vendor.audio.mp3.complexity.default=10
vendor.audio.mp3.quality=100
vendor.audio.mpegh.complexity.default=10
vendor.audio.mpegh.quality=100
vendor.audio.amrnb.complexity.default=10
vendor.audio.amrnb.quality=100
vendor.audio.amrwb.complexity.default=10
vendor.audio.amrwb.quality=100
vendor.audio.g711.alaw.complexity.default=10
vendor.audio.g711.alaw.quality=100
vendor.audio.g711.mlaw.complexity.default=10
vendor.audio.g711.mlaw.quality=100
vendor.audio.opus.complexity.default=10
vendor.audio.opus.quality=100
vendor.audio.raw.complexity.default=10
vendor.audio.raw.quality=100
vendor.audio.flac.complexity.default=10
vendor.audio.flac.quality=100
vendor.audio.dsp.complexity.default=10
vendor.audio.dsp.quality=100
vendor.audio.dsd.complexity.default=10
vendor.audio.dsd.quality=100
vendor.audio.alac.complexity.default=10
vendor.audio.alac.quality=100

use.non-omx.alac.decoder=false
use.non-omx.mpegh.decoder=false
use.non-omx.vorbis.decoder=false
use.non-omx.wma.decoder=false
use.non-omx.amrnb.decoder=false
use.non-omx.amrwb.decoder=false
use.non-omx.mhas.decoder=false
use.non-omx.g711.alaw.decoder=false
use.non-omx.g711.mlaw.sw.decoder=false
use.non-omx.opus.decoder=false
use.non-omx.raw.decoder=false
use.non-omx.qti.decoder=false
use.non-omx.dsp.decoder=false
use.non-omx.dsd.decoder=false
use.non-omx.alac.encoder=false
use.non-omx.mpegh.encoder=false
use.non-omx.flac.encoder=false
use.non-omx.aac.encoder=false
use.non-omx.vorbis.encoder=false
use.non-omx.wma.encoder=false
use.non-omx.mp3.encoder=false
use.non-omx.amrnb.encoder=false
use.non-omx.amrwb.encoder=false
use.non-omx.mhas.encoder=false
use.non-omx.g711.alaw.encoder=false
use.non-omx.g711.mlaw.sw.encoder=false
use.non-omx.opus.encoder=false
use.non-omx.raw.encoder=false
use.non-omx.qti.encoder=false
use.non-omx.dsp.encoder=false
use.non-omx.dsd.encoder=false

media.aac_51_output_enabled=true
mm.enable.smoothstreaming=true
mmp.enable.3g2=true
mm.enable.qcom_parser=63963135
vendor.mm.enable.qcom_parser=63963135

lpa.decode=false
lpa30.decode=false
lpa.use-stagefright=false
lpa.releaselock=false

audio.playback.mch.downsample=false
vendor.audio.playback.mch.downsample=false
persist.vendor.audio.playback.mch.downsample=false

ro.hardware.hifi.support=true
ro.audio.hifi=true
ro.vendor.audio.hifi=true
persist.audio.hifi=true
persist.vendor.audio.hifi=true
persist.audio.hifi.volume=92
persist.audio.hifi.int_codec=true
persist.vendor.audio.hifi.int_codec=true

effect.reverb.pcm=1
vendor.audio.safx.pbe.enabled=true
vendor.audio.soundfx.usb=false
vendor.audio.keep_alive.disabled=false
ro.vendor.audio.soundfx.usb=false
ro.vendor.audio.sfx.speaker=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.scenario=false
ro.vendor.audio.sfx.audiovisual=false
ro.vendor.audio.sfx.independentequalizer=false
ro.vendor.audio.3d.audio.support=true
persist.vendor.audio.ambisonic.capture=true
persist.vendor.audio.ambisonic.auto.profile=true

vendor.voice.dsd.playback.conc.disabled=false
vendor.audio.hdr.record.enable=true
vendor.audio.3daudio.record.enable=true
ro.vendor.audio.recording.hd=true
ro.ril.enable.amr.wideband=1
persist.audio.lowlatency.rec=true

vendor.audio.matrix.limiter.enable=0
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.audio.hal.output.suspend.supported=true
vendor.audio.snd_card.open.retries=50
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.tfa9874.dsp.enabled=true
ro.audio.soundtrigger.lowpower=false
ro.vendor.audio.soundtrigger.adjconf=true
ro.vendor.audio.enhance.support=true
ro.vendor.audio.gain.support=true
persist.vendor.audio.ll_playback_bargein=true
persist.vendor.audio.bcl.enabled=false
persist.vendor.audio.delta.refresh=true

ro.audio.resampler.psd.enable_at_samplerate=192000
ro.audio.resampler.psd.stopband=179
ro.audio.resampler.psd.halflength=408
ro.audio.resampler.psd.cutoff_percent=99
ro.audio.resampler.psd.tbwcheat=100

vendor.qc2audio.suspend.enabled=true
vendor.qc2audio.per_frame.flac.dec.enabled=true
vendor.audio.lowpower=false

vendor.audio.c2.preferred=true
debug.c2.use_dmabufheaps=1
ro.vendor.audio.sfx.harmankardon=true

ro.vendor.audio.bass.enhancer.enable=true
audio.safemedia.bypass=true
ro.audio.usb.period_us=2625

#change usb period
ro.audio.usb.period_us=50000
vendor.audio.usb.perio=50000
vendor.audio.usb.out.period_us=50000
vendor.audio.usb.out.period_count=2

#new11102022
persist.vendor.audio.spv4.enable=true
ro.vendor.audio.ns.support=true
ro.vendor.audio.enhance.support=true
ro.vendor.audio.karaok.support=true
ro.audio.monitorRotation=true
ro.audio.recording.hd=true
ro.vendor.audio.spk.clean=true
persist.vendor.vcb.enable=true
persist.vendor.vcb.ability=true
defaults.pcm.rate_converter=samplerate_best
ro.vendor.audio.sdk.ssr=true
ro.vendor.audio.dump.mixer=false
ro.audio.playbackScene=false
ro.vendor.audio.playbackScene=false
ro.vendor.audio.recording.hd=true
ro.vendor.audio.multiroute=true
ro.vendor.audio.sos=true
ro.vendor.audio.voice.change.support=true
ro.vendor.audio.voice.change.youme.support=true
ro.vendor.audio.spk.stereo=true
ro.vendor.audio.spk.clean=true
ro.vendor.audio.vocal.support=true
ro.vendor.audio.sfx.independentequalizer=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.speaker=true
ro.vendor.audio.sfx.spk.movie=true
ro.vendor.audio.gain.support=true
ro.vendor.audio.karaok.support=true
ro.vendor.camera.karaok.support=true
ro.vendor.audio.ns.support=true
ro.vendor.audio.enhance.support=true
ro.audio.monitorRotation=true
ro.vendor.audio.monitorRotation=true
ro.vendor.audio.game.mode=true
ro.vendor.audio.game.vibrate=true
ro.vendor.audio.aiasst.support=true
ro.vendor.audio.soundtrigger.lowpower=false
ro.vendor.audio.soundtrigger.adjconf=false
ro.vendor.audio.soundtrigger.pangaea=0
ro.vendor.audio.soundtrigger.sva-5.0=1
ro.vendor.audio.soundtrigger.sva-6.0=1
ro.vendor.audio.soundfx.usb=true
ro.vendor.audio.ring.filter=true
ro.vendor.audio.feature.fade=true
ro.vendor.audio.us.proximity=false
ro.vendor.audio.camera.loopback.support=true
ro.vendor.audio.support.sound.id=true
ro.vendor.standard.video.enable=true
ro.vendor.audio.videobox.switch=true
ro.vendor.video_box.version=2
ro.vendor.audio.feature.spatial=7
ro.vendor.audio.multichannel.5point1.headset=true
ro.vendor.audio.multichannel.5point1=true
ro.vendor.audio.notify5Point1InUse=true
ro.vendor.audio.multi.channel=true
ro.vendor.audio.dolby.eq.half=false
ro.vendor.audio.dolby.vision.support=false
ro.vendor.audio.dolby.vision.capture.support=false
ro.vendor.audio.dolby.surround.enable=false
ro.vendor.audio.surround.support=false
ro.vendor.audio.surround.headphone.only=false
ro.vendor.audio.elus.enable=true
ro.vendor.audio.sfx.scenario=true

audio.high.resolution.enable=true
vendor.audio.high.resolution.enable=true
vendor.audio.offload.buffer.size.kb=384
audio.native.dsd.buffer.size.kb=1024
vendor.audio.native.dsd.buffer.size.kb=1024
audio.truehd.buffer.size.kb=256
vendor.audio.truehd.buffer.size.kb=256

vendor.audio.matrix.limiter.enable=0
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.audio.hal.output.suspend.supported=true
vendor.audio.snd_card.open.retries=50
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.tfa9874.dsp.enabled=true
ro.audio.soundtrigger.lowpower=false
ro.vendor.audio.soundtrigger.adjconf=true
ro.vendor.audio.ns.support=true
ro.vendor.audio.enhance.support=true
ro.vendor.audio.gain.support=true
persist.vendor.audio.ll_playback_bargein=true
persist.vendor.audio.bcl.enabled=false
persist.vendor.audio.format.24bit=true
persist.vendor.audio.delta.refresh=true" >> $MODPATH/system.prop
fi

if [ "$STEP12" == "true" ]; then
echo -e "\n# Bluetooth
audio.effect.a2dp.enable=1
vendor.audio.effect.a2dp.enable=1
qcom.hw.aac.encoder=true
qcom.hw.aac.decoder=true
persist.service.btui.use_aptx=1
persist.bt.enableAptXHD=true
persist.bt.a2dp.aptx_disable=false
persist.bt.a2dp.aptx_hd_disable=false
persist.bt.a2dp.aac_disable=false
persist.bt.sbc_hd_enabled=1
persist.vendor.btstack.enable.lpa=false
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.bt.aac_frm_ctl.enabled=true
persist.vendor.bt.aac_vbr_frm_ctl.enabled=true
persist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true
persist.vendor.btstack.enable.twsplussho=true
persist.vendor.qcom.bluetooth.twsp_state.enabled=false
persist.bluetooth.sbc_hd_higher_bitrate=1
persist.sys.fflag.override.settings_bluetooth_hearing_aid=true
persist.vendor.qcom.bluetooth.aptxadaptiver2_2_support=true
#new11102022
persist.rcs.supported=1
persist.vendor.btstack.enable.swb=true
persist.vendor.btstack.enable.swbpm=true
persist.vendor.qcom.bluetooth.enable.swb=true" >> $MODPATH/system.prop
fi


ui_print " "
ui_print "   ######################################## 100% done!"

ui_print " "
ui_print " - All done! With love, NLSound Team. - "
ui_print " "

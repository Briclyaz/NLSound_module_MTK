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

[ -f /system/vendor/build.prop ] && BUILDS="/system/build.prop /system/vendor/build.prop /my_product/build.prop" || BUILDS="/system/build.prop"
MTKG90T=$(grep "ro.board.platform=mt6785" $BUILDS)
HELIOA22=$(grep "ro.board.platform=mt6765" $BUILDS)
HELIOG85G88=$(grep "ro.board.platform=mt6768" $BUILDS)
MT6875=$(grep "ro.board.platform=mt6873" $BUILDS)
DIMENSITY8100=$(grep "ro.board.platform=mt6895" $BUILDS)

#devices
RN8PRO=$(grep -E "ro.product.vendor.device=begonia.*|ro.product.vendor.device=begonianin.*" $BUILDS)
R10X4GNOTE9=$(grep -E "ro.product.vendor.device=merlin.*" $BUILDS)
R10XPRO5G=$(grep -E "ro.product.vendor.device=bomb.*" $BUILDS)
R10X5G=$(grep -E "ro.product.vendor.device=atom.*" $BUILDS)
POCOX4GT=$(grep -E "ro.product.vendor.device=xaga.*" $BUILDS)
ONEPLUSACE=$(grep -E "ro.build.product=CPH2411.*|ro.build.product=CPH2423.*|ro.build.product=PKGM10.*" $BUILDS)

ADEVS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "*audio_device*.xml")"
AUEMS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "*audio_em*.xml")"
AURCONFS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "*aurisys_config*.xml")"
MCODECS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "media_codecs_c2_audio.xml" -o -name "media_codecs_c2.xml" -o -name "media_codecs_google_audio.xml" -o -name "media_codecs_google_c2_audio.xml")"
DSMS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "DSM*.xml")"
DSMCONFIGS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "DSM_config*.xml")"
APAROPTS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "*AudioParamOptions*.xml")"
IMPAUPARMS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "*HpImpedance_AudioParam*.xml")"

VNDK=$(find /system/lib /vendor/lib -type d -iname "*vndk*")
VNDK64=$(find /system/lib64 /vendor/lib64 -type d -iname "*vndk*")
VNDKQ=$(find /system/lib /vendor/lib -type d -iname "vndk*-Q")

SETTINGS=$MODPATH/settings.nls
PROP=$MODPATH/system.prop

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


mkdir -p $MODPATH/tools
cp_ch $MODPATH/common/addon/External-Tools/tools/$ARCH32/\* $MODPATH/tools/.

ui_print " - Configurate me, pls >.< -"
ui_print " "
ui_print "***************************************************"
ui_print "* [1/11]                                          *"
ui_print "*                                                 *"
ui_print "*       • CONFIGURE INTERNAL AUDIO CODEC •        *"
ui_print "*                                                 *"
ui_print "* This option configure your interal audio codec. *"
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
ui_print "* [2/11]                                          *"
ui_print "*                                                 *"
ui_print "*            • SWITCH SPEAKER CLASS •             *"
ui_print "*                                                 *"
ui_print "*   This option switch speaker class on Hi-Fi.    *"
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
ui_print "* [3/11]                                          *"
ui_print "*                                                 *"
ui_print "*          • ENABLE LOW LATENCY & PULSE •         *"
ui_print "*                                                 *"
ui_print "*    This option enable low latency route and     *"
ui_print "*        activate support pulse technology.       *"
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
ui_print "* [4/11]                                          *"
ui_print "*                                                 *"
ui_print "*          • CONFIGURE MEDIATEK BESSOUND •        *"
ui_print "*                                                 *"
ui_print "*      This option configure MediaTek Bessound    *"
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
ui_print "* [5/11]                                          *"
ui_print "*                                                 *"
ui_print "*       • PATCHING DEVICE_FEATURES FILES •        *"
ui_print "*                                                 *"
ui_print "*        This step will do the following:         *"
ui_print "*        - Unlocks the sampling frequency         *"
ui_print "*          of the audio up to 192000 Hz;          *"
ui_print "*        - Enable HD record in camcorder;         *"
ui_print "*        - Increase VoIP record quality;          *"
ui_print "*        - Enable support for hd voice            *"
ui_print "*          recording quality;                     *"
ui_print "*        - Enable Hi-Fi support (on some devices) *"
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
ui_print "* [6/11]                                          *"
ui_print "*                                                 *"
ui_print "*        • TRY UNLOCK MORE IMPEDANCES  •          *" 
ui_print "*                                                 *"
ui_print "*     Attempts to unlock additional options:      *"
ui_print "*                   - 24 ohm;                     *"
ui_print "*                   - 48 ohm;                     *"
ui_print "*                   - 96 ohm;                     *"
ui_print "*                   - 192 ohm;                    *"
ui_print "*       May not be supported by the device        *" 
ui_print "*              and cause problems.                *"
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
ui_print "* [7/11]                                          *"
ui_print "*                                                 *"
ui_print "*        • CONFIGURE ALL MEDIA CODECS •           *"
ui_print "*                                                 *"
ui_print "*        This step patching media codecs          *"
ui_print "*     in your system for improving quality.       *"
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
ui_print "* [8/11]                                          *"
ui_print "*                                                 *"
ui_print "*       • CONFIGURE VOLTAGES FOR DSP •            *"
ui_print "*                                                 *"
ui_print "*        This step patching DSM files             *"
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
ui_print "* [9/11]                                          *"
ui_print "*                                                 *"
ui_print "*         • TWEAKS FOR BUILD.PROP FILES •         *"
ui_print "*                                                 *"
ui_print "*     A huge number of global settings that       *"
ui_print "*      greatly change the quality of audio        *"
ui_print "*   for the better. Don't hesitate and just go    *"
ui_print "*         along with the installation.            *"
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
ui_print "* [10/11]                                         *"
ui_print "*                                                 *"
ui_print "*             • IMPROVE BLUETOOTH •               *"
ui_print "*                                                 *"
ui_print "*   This option will improve the audio quality    *"
ui_print "*    in Bluetooth, as well as fix the problem     *"
ui_print "*      of disappearing the AAC codec switch       *"
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
ui_print "* [11/11]                                         *"
ui_print "*                                                 *"
ui_print "*          • IGNORE ALL AUDIO EFFECTS •           *"
ui_print "*                                                 *"
ui_print "*      This item disables any audio effects       *"
ui_print "*   at the system level. It breaks XiaomiParts,   *"
ui_print "*      Dirac, Dolby, and other equalizers.        *"
ui_print "*   Significantly increases the sound quality     *"
ui_print "*            for quality headphones.              *"
ui_print "*                                                 *"
ui_print "*                     Note:                       *"
ui_print "*     If you agree, the sound becomes drier,      *"
ui_print "*                  "cleaner".                     *"
ui_print "*      However, many people are advised to        *"
ui_print "*               skip this point.                  *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP11=true
sed -i 's/STEP11=false/STEP11=true/g' $SETTINGS
fi

ui_print " - YOUR SETTINGS: "
ui_print " 1. Configure internal audio codec: $STEP1"
ui_print " 2. Switch speaker class: $STEP2"
ui_print " 3. Enabe low latency and pulse: $STEP3"
ui_print " 4. Configure mediatek bessound: $STEP4"
ui_print " 5. Patching device_features files: $STEP5"
ui_print " 6. Try unlock more impedances: $STEP6"
ui_print " 7. Configure all media codecs: $STEP7"
ui_print " 8. Configure voltages for DSP: $STEP8"
ui_print " 9. Tweaks for build.prop files: $STEP9"
ui_print " 10. Improve Bluetooth: $STEP10"
ui_print " 11. Ignore all audio effects: $STEP11"
ui_print " "

ui_print " "
ui_print " - Processing. . . -"
ui_print " "
ui_print " - You can minimize Magisk and use the device normally -"
ui_print " - and then come back here to reboot and apply the changes. -"
ui_print " "

#audio parameters
if [ "$STEP1" == "true" ]; then
for OAPAROPTS in ${APAROPTS}; do 
APAR="$MODPATH$(echo $OAPAROPTS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OAPAROPTS $APAR
sed -i 's/\t/  /g' $APAR
sed -i 's/Param name="MTK_WB_SPEECH_SUPPORT" value=".*"/Param name="MTK_WB_SPEECH_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_HD_REC_SUPPORT" value=".*"/Param name="MTK_WB_MTK_AUDIO_HD_REC_SUPPORTSPEECH_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_HANDSFREE_DMNR_SUPPORT" value=".*"/Param name="MTK_HANDSFREE_DMNR_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="DMNR_TUNNING_AT_MODEMSIDE" value=".*"/Param name="DMNR_TUNNING_AT_MODEMSIDE" value=""/g' $APAR
sed -i 's/Param name="MTK_VOIP_ENHANCEMENT_SUPPORT" value=".*"/Param name="MTK_VOIP_ENHANCEMENT_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_TB_WIFI_3G_MODE" value=".*"/Param name="MTK_TB_WIFI_3G_MODE" value=""/g' $APAR
sed -i 's/Param name="MTK_ACF_AUTO_GEN_SUPPORT" value=".*"/Param name="MTK_ACF_AUTO_GEN_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_AUDIO_BLOUD_CUSTOMPARAMETER_REV" value=".*"/Param name="MTK_AUDIO_BLOUD_CUSTOMPARAMETER_REV" value=""/g' $APAR
sed -i 's/Param name="MTK_MAGICONFERENCE_SUPPORT" value=".*"/Param name="MTK_MAGICONFERENCE_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_HAC_SUPPORT" value=".*"/Param name="MTK_HAC_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MATV_AUDIO_SUPPORT" value=".*"/Param name="MATV_AUDIO_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_FM_SUPPORT" value=".*"/Param name="MTK_FM_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_WB_SPEECH_SUPMTK_SUPPORT_TC1_TUNNINGPORT" value=".*"/Param name="MTK_WB_SPEECH_SUPMTK_SUPPORT_TC1_TUNNINGPORT" value=""/g' $APAR
sed -i 's/Param name="MTK_AURISYS_FRAMEWORK_SUPPORT" value=".*"/Param name="MTK_AURISYS_FRAMEWORK_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_BESLOUDNESS_RUN_WITH_HAL" value=".*"/Param name="MTK_BESLOUDNESS_RUN_WITH_HAL" value="yes"/g' $APAR
sed -i 's/Param name="MTK_AUDIO" value=".*"/Param name="MTK_AUDIO" value="yes"/g' $APAR
sed -i 's/Param name="USE_CUSTOM_AUDIO_POLICY" value=".*"/Param name="USE_CUSTOM_AUDIO_POLICY" value=""/g' $APAR
sed -i 's/Param name="MTK_SMARTPA_DUMMY_LIB" value=".*"/Param name="MTK_SMARTPA_DUMMY_LIB" value=""/g' $APAR
sed -i 's/Param name="MTK_HIFIAUDIO_SUPPORT" value=".*"/Param name="MTK_HIFIAUDIO_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_BESLOUDNESS_SUPPORT" value=".*"/Param name="MTK_BESLOUDNESS_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="MTK_A2DP_OFFLOAD_SUPPORT" value=".*"/Param name="MTK_A2DP_OFFLOAD_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_TTY_SUPPORT" value=".*"/Param name="v" value="yes"/g' $APAR
sed -i 's/Param name="VIR_WIFI_ONLY_SUPPORT" value=".*"/Param name="VIR_WIFI_ONLY_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_3G_DATA_ONLY_SUPPORT" value=".*"/Param name="VIR_3G_DATA_ONLY_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_ASR_SUPPORT" value=".*"/Param name="VIR_ASR_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_NO_SPEECH" value=".*"/Param name="VIR_NO_SPEECH" value="no"/g' $APAR
sed -i 's/Param name="VIR_INCALL_NORMAL_DMNR_SUPPORT" value=".*"/Param name="VIR_INCALL_NORMAL_DMNR_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="VIR_INCALL_HANDSFREE_DMNR_SUPPORT" value=".*"/Param name="VIR_INCALL_HANDSFREE_DMNR_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="VIR_VOICE_UNLOCK_SUPPORT" value=".*"/Param name="VIR_VOICE_UNLOCK_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V5" value=".*"/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V5" value="yes"/g' $APAR
sed -i 's/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V4" value=".*"/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V4" value="no"/g' $APAR
sed -i 's/Param name="VIR_MAGI_CONFERENCE_SUPPORT" value=".*"/Param name="VIR_MAGI_CONFERENCE_SUPPORT" value="no"/g' $APAR
sed -i 's/Param name="MTK_AUDIO_HIERARCHICAL_PARAM_SUPPORT" value=".*"/Param name="MTK_AUDIO_HIERARCHICAL_PARAM_SUPPORT" value="yes"/g' $APAR
sed -i 's/Param name="5_POLE_HS_SUPPORT" value=".*"/Param name="5_POLE_HS_SUPPORT" value=""/g' $APAR
sed -i 's/Param name="VIR_MTK_USB_PHONECALL" value=".*"/Param name="VIR_MTK_USB_PHONECALL" value="yes"/g' $APAR
sed -i 's/Param name="SPK_PATH_NO_ANA" value=".*"/Param name="SPK_PATH_NO_ANA" value="yes"/g' $APAR
sed -i 's/Param name="RCV_PATH_INT" value=".*"/Param name="RCV_PATH_INT" value="yes"/g' $APAR
sed -i 's/Param name="SPH_PARAM_VERSION" value=".*"/Param name="SPH_PARAM_VERSION" value="3.0"/g' $APAR
sed -i 's/Param name="SPH_PARAM_TTY" value=".*"/Param name="SPH_PARAM_TTY" value="yes"/g' $APAR
sed -i 's/Param name="FIX_WB_ENH" value=".*"/Param name="FIX_WB_ENH" value="yes"/g' $APAR
sed -i 's/Param name="SPH_PARAM_SV" value=".*"/Param name="SPH_PARAM_SV" value="yes"/g' $APAR
sed -i 's/Param name="VIR_SCENE_CUSTOMIZATION_SUPPORT" value=".*"/Param name="VIR_SCENE_CUSTOMIZATION_SUPPORT" value="yes"/g' $APAR
done
fi

if [ "$STEP2" == "true" ]; then
for OADEV in ${ADEVS}; do
ADEV="$MODPATH$(echo $OADEV | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OADEV $ADEV
sed -i 's/\t/  /g' $ADEV
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Speaker_class_Switch"]' "CLASSH"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Debug_Setting"]' "1"
patch_xml -u $ADEV '/root/mixercontrol/kctl[@name="Audio_Codec_Debug_Setting"]' "1"
done
fi

ui_print " "
ui_print "   ########================================ 20% done!"


if [ "$STEP3" == "true" ]; then
for OAUEM in ${AUEMS}; do
AUEM="$MODPATH$(echo $OAUEM | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OAUEM $AUEM
sed -i 's/\t/  /g' $AUEM
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="TDM_Record"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="SET_MODE"]' "0"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="LowLatencyDebugEnable"]' "1"
patch_xml -u $AUEM '/AudioParameter/SetParameters[@name="DetectPulseEnable"]' "1"
done
fi

if [ "$STEP4" == "true" ]; then
for OAURCONF in ${AURCONFS}; do
AURCONF="$MODPATH$(echo $OAURCONF | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OAURCONF $AURCONF
sed -i 's/\t/  /g' $AURCONF
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_bessound"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_iir"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_32_BIT"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="sample_rate"]' "8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000"
patch_xml -u $AURCONF '/aurisys_config/library[@name="mtk_speech_enh"]/components/component[@name="audio_format"]' "AUDIO_FORMAT_PCM_8_24_BIT"
done
fi

ui_print " "
ui_print "   ################======================== 40% done!"

if [ "$STEP5" == "true" ]; then
for ODEVFEA in ${DEVFEAS}; do 
DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
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

if [ "$STEP6" == "true" ]; then
for OAIMPAUPARMS in ${IMPAUPARMS}; do 
IMPAUPARM="$MODPATH$(echo $OAIMPAUPARMS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OAIMPAUPARMS $IMPAUPARM
sed -i 's/\t/  /g' $IMPAUPARM
sed -i 's/Param name="hp_impedance_enable" value="0"/Param name="hp_impedance_enable" value="1"/g' $IMPAUPARM
done
fi

ui_print " "                 
ui_print "   ########################================ 60% done!"

#patching media codecs files
if [ "$STEP7" == "true" ]; then
for OMCODECS in ${MCODECS}; do
MEDIACODECS="$MODPATH$(echo $OMCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OMCODECS $MEDIACODECS
sed -i 's/\t/  /g' $MEDIACODECS
sed -i 's/<<!--.*-->>//; s/<!--.*-->>//; s/<<!--.*-->//; s/<!--.*-->//; /<!--/,/-->/d; /^ *#/d; /^ *$/d' $MEDIACODECS
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
sed -i '/^ *#/d; /^ *$/d' $MEDIACODECS
done
fi

if [ "$STEP8" == "true" ]; then
#dsm
for ODSMS in ${DSMS}; do
DSM="$MODPATH$(echo $ODSMS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$ODSMS $DSM
sed -i 's/\t/  /g' $DSM
sed -i 's/params type="*"/params type="float"/g' $DSM
sed -i 's/currentv="*"/currentv="123.000000"/g' $DSM
done
fi

ui_print " "                 
ui_print "   ################################======== 80% done!"

if [ "$STEP9" == "true" ]; then
echo -e "\n# Better parameters audio by NLSound Team
flac.sw.decoder.24bit.support=true
vendor.audio.flac.sw.decoder.24bit=true
vendor.audio.aac.sw.decoder.24bit=true
vendor.audio.mp3.sw.decoder.24bit=true
vendor.audio.ac3.sw.decoder.24bit=true
vendor.audio.eac3.sw.decoder.24bit=true
vendor.audio.eac3_joc.sw.decoder.24bit=true
vendor.audio.ac4.sw.decoder.24bit=true
vendor.audio.opus.sw.decoder.24bit=true
vendor.audio.dsp.sw.decoder.24bit=true
vendor.audio.dsd.sw.decoder.24bit=true
vendor.audio.flac.sw.encoder.24bit=true
vendor.audio.aac.sw.encoder.24bit=true
vendor.audio.mp3.sw.encoder.24bit=true
vendor.audio.raw.sw.encoder.24bit=true
vendor.audio.ac3.sw.encoder.24bit=true
vendor.audio.eac3.sw.encoder.24bit=true
vendor.audio.eac3_joc.sw.encoder.24bit=true
vendor.audio.ac4.sw.encoder.24bit=true
vendor.audio.opus.sw.encoder.24bit=true
vendor.audio.dsp.sw.encoder.24bit=true
vendor.audio.dsd.sw.encoder.24bit=true

vendor.audio.flac.complexity.default=10
vendor.audio.flac.quality=100
vendor.audio.aac.complexity.default=10
vendor.audio.aac.quality=100
vendor.audio.mp3.complexity.default=10
vendor.audio.mp3.quality=100
vendor.audio.ac3.complexity.default=10
vendor.audio.ac3.quality=100
vendor.audio.eac3.complexity.default=10
vendor.audio.eac3.quality=100
vendor.audio.eac3_joc.complexity.default=10
vendor.audio.eac3_joc.quality=100
vendor.audio.ac4.complexity.default=10
vendor.audio.ac4.quality=100
vendor.audio.opus.complexity.default=10
vendor.audio.opus.quality=100
vendor.audio.dsp.complexity.default=10
vendor.audio.dsp.quality=100
vendor.audio.dsd.complexity.default=10
vendor.audio.dsd.quality=100

use.non-omx.flac.decoder=false
use.non-omx.aac.decoder=false
use.non-omx.mp3.decoder=false
use.non-omx.raw.decoder=false
use.non-omx.ac3.decoder=false
use.non-omx.ac4.decoder=false
use.non-omx.opus.decoder=false
use.non-omx.dsp.decoder=false
use.non-omx.dsd.decoder=false
use.non-omx.flac.encoder=false
use.non-omx.aac.encoder=false
use.non-omx.mp3.encoder=false
use.non-omx.raw.encoder=false
use.non-omx.ac3.encoder=false
use.non-omx.ac4.encoder=false
use.non-omx.opus.encoder=false
use.non-omx.dsp.encoder=false
use.non-omx.dsd.encoder=false

af.thread.throttle=0
af.fast_downmix=1
ro.vendor.af.raise_bt_thread_prio=true

audio.decoder_override_check=true
media.stagefright.thumbnail.prefer_hw_codecs=true

vendor.audio.tunnel.encode=true
tunnel.audio.encode=true
tunnel.audiovideo.decode=true
tunnel.decode=true

lpa.decode=false
lpa30.decode=false
lpa.use-stagefright=false
lpa.releaselock=false

audio.playback.mch.downsample=false
persist.vendor.audio.playback.mch.downsample=false

vendor.audio.feature.dsm_feedback.enable=true
vendor.audio.feature.dynamic_ecns.enable=true
vendor.audio.feature.external_dsp.enable=true
vendor.audio.feature.external_speaker.enable=true
vendor.audio.feature.external_speaker_tfa.enable=true
vendor.audio.feature.spkr_prot.enable=false
vendor.audio.feature.ext_hw_plugin.enable=true
vendor.audio.feature.keep_alive.enable=true
vendor.audio.feature.compress_meta_data.enable=false
vendor.audio.feature.compr_cap.enable=false
vendor.audio.feature.devicestate_listener.enable=false
vendor.audio.feature.thermal_listener.enable=false
vendor.audio.feature.power_mode.enable=true
vendor.audio.feature.hifi_audio.enable=true
vendor.audio.feature.deepbuffer_as_primary.enable=false 
vendor.audio.feature.dmabuf.cma.memory.enable=true
vendor.audio.feature.battery_listener.enable=false
vendor.audio.feature.custom_stereo.enable=true
vendor.audio.feature.wsa.enable=true

vendor.audio.usb.super_hifi=true
ro.audio.hifi=true
ro.config.hifi_always_on=true
ro.config.hifi_enhance_support=1
ro.hardware.hifi.support=true
ro.vendor.audio.hifi=true
persist.audio.hifi=true
persist.audio.hifi.volume=1
persist.audio.hifi.int_codec=true
persist.audio.hifi_adv_support=1
persist.audio.hifi_dac=ON
persist.vendor.audio.hifi_enabled=true
persist.audio.hifi.int_codec=true 
persist.vendor.audio.hifi.int_codec=true
ro.config.hifi_config_state=2

audio.spatializer.effect.util_clamp_min=300
effect.reverb.pcm=1
sys.vendor.atmos.passthrough=enable
vendor.audio.dolby.ds2.enabled=true
vendor.audio.keep_alive.disabled=false
vendor.audio.dolby.control.support=true
vendor.audio.dolby.control.tunning.by.volume.support=true
ro.vendor.audio.elus.enable=true
ro.audio.spatializer_enabled=true
ro.vendor.audio.soundfx.usb=false
ro.vendor.audio.sfx.speaker=false 
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.scenario=false 
ro.vendor.audio.sfx.independentequalizer=false
ro.vendor.audio.surround.support=true
ro.vendor.audio.dolby.eq.half=true
ro.vendor.audio.dolby.surround.enable=true
ro.vendor.audio.dolby.fade_switch=true
ro.vendor.media.video.meeting.support=true
persist.vendor.audio.ambisonic.capture=true
persist.vendor.audio.ambisonic.auto.profile=true

audio.record.delay=0
vendor.voice.dsd.playback.conc.disabled=false
vendor.audio.3daudio.record.enable=true
vendor.audio.hdr.spf.record.enable=true
vendor.audio.hdr.record.enable=true
vendor.audio.chk.cal.us=1
ro.vendor.audio.recording.hd=true
ro.vendor.audio.sdk.ssr=false
persist.audio.lowlatency.rec=true
persist.vendor.audio.endcall.delay=0
persist.vendor.audio.record.ull.support=true

audio.offload.24bit.enable=1
vendor.usb.analog_audioacc_disabled=false
vendor.audio.enable.cirrus.speaker=true
vendor.audio.sys.init=true
vendor.audio.trace.enable=true
vendor.audio.powerop=true
vendor.audio.read.wsatz.type=true
vendor.audio.powerhal.power.ul=true
vendor.audio.powerhal.power.dl=true
vendor.audio.powerhal.power.hi_bitrate=true
vendor.audio.hal.boot.timeout.ms=5000
vendor.audio.LL.coeff=100
vendor.audio.caretaker.at=true
vendor.audio.matrix.limiter.enable=0
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.audio.hal.output.suspend.supported=false
vendor.audio.snd_card.open.retries=50
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.camera.unsupport_low_latency=false 
vendor.audio.tfa9874.dsp.enabled=true
vendor.audio.lowpower=false
vendor.audio.compress_capture.enabled=false 
vendor.audio.compress_capture.aac=false
vendor.audio.rt.mode=23
vendor.audio.rt.mode.onlyfast=false 
vendor.audio.cpu.sched=31
vendor.audio.cpu.sched.cpuset=248
vendor.audio.cpu.sched.cpuset.binder=255
vendor.audio.cpu.sched.cpuset.at=248
vendor.audio.cpu.sched.cpuset.af=248
vendor.audio.cpu.sched.cpuset.hb=248
vendor.audio.cpu.sched.cpuset.hso=248
vendor.audio.cpu.sched.cpuset.he=248
vendor.audio.cpu.sched.cpus=8
vendor.audio.cpu.sched.onlyfast=false 
vendor.media.amplayer.audiolimiter=false 
vendor.media.amplayer.videolimiter=false 
vendor.media.audio.ms12.downmixmode=on
ro.audio.resampler.psd.enable_at_samplerate=192000
ro.audio.resampler.psd.halflength=240
ro.audio.resampler.psd.stopband=20
ro.audio.resampler.psd.cutoff_percent=100
ro.audio.resampler.psd.tbwcheat=110
ro.audio.soundtrigger.lowpower=false
ro.vendor.audio.soundtrigger.lowpower=false
ro.vendor.audio_tunning.dual_spk=2
ro.vendor.audio_tunning.nr=1
ro.vendor.audio.frame_count_needed_constant=32768
ro.vendor.audio.soundtrigger.wakeupword=5
ro.vendor.audio.ce.compensation.need=true
ro.vendor.audio.ce.compensation.value=5
ro.vendor.audio.enhance.support=true
ro.vendor.audio.gain.support=true
ro.vendor.audio.spk.clean=false
ro.vendor.audio.3d.audio.support=true
ro.vendor.audio.pastandby=true
ro.vendor.audio.dpaudio=true
ro.vendor.audio.spk.stereo=true
ro.vendor.audio.dualadc.support=true
ro.vendor.audio.meeting.mode=true
ro.vendor.media.support.omx2=true
ro.vendor.platform.disable.audiorawout=false
ro.vendor.platform.has.realoutputmode=true
ro.vendor.platform.support.dolby=true
ro.vendor.platform.support.dts=true
ro.vendor.usb.support_analog_audio=true
ro.mediaserver.64b.enable=true
persist.audio.hp=true
persist.config.speaker_protect_enabled=0
#test3
persist.vendor.audio.spv3.enable=false

persist.sys.audio.source=true
persist.vendor.audio.bcl.enabled=false
persist.vendor.audio.cca.enabled=true
persist.vendor.audio.misoundasc=true
persist.vendor.audio.okg_hotword_ext_dsp=true
persist.vendor.audio.format.24bit=true
persist.vendor.audio.speaker.stereo=true
persist.vendor.audio_hal.dsp_bit_width_enforce_mode=24

persist.vendor.audio.ll_playback_bargein=true
persist.vendor.audio.delta.refresh=true

#test
alsa.mixer.playback.master=DAC1
#test2
ro.config.hw_audio_plus=true
ro.mtk_audenh_support=1

persist.vendor.audio.delta.refresh=true 
ro.vendor.audio.camera.bt.record.support=true
ro.vendor.mtk_hifiaudio_support=1
ro.vendor.mtk_audio_alac_support=1
ro.vendor.mtk_audio_ape_support=1
ro.vendor.mtk_audio_flac_support=1
ro.vendor.mtk_audio_tuning_tool_ver=V2.2
ro.vendor.mtk_besloudness_support=1
vendor.audio.usb.perio=2625
vendor.audio.usb.period_us=2625" >> $PROP
#exit
fi

if [ "$STEP10" == "true" ]; then
echo -e "\n# Bluetooth parameters by NLSound Team
config.disable_bluetooth=false
bluetooth.profile.a2dp.source.enabled=true
vendor.audio.effect.a2dp.enable=1
vendor.bluetooth.ldac.abr=false 
vendor.media.audiohal.btwbs=true
ro.vendor.audio.hw.aac.encoder=true
ro.vendor.audio.hw.aac.decoder=true
persist.service.btui.use_aptx=1
persist.bt.a2dp.aac_disable=false
persist.bt.sbc_hd_enabled=1
persist.bt.power.down=false 
persist.vendor.audio.sys.a2h_delay_for_a2dp=50
persist.vendor.btstack.enable.lpa=false
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.bt.aac_frm_ctl.enabled=true
persist.vendor.bt.aac_vbr_frm_ctl.enabled=true
persist.vendor.bt.splita2dp.44_1_war=true
persist.vendor.btstack.enable.twsplussho=true
persist.vendor.btstack.enable.twsplus=true
persist.vendor.bluetooth.prefferedrole=master
persist.vendor.bluetooth.leaudio_mode=off
persist.bluetooth.a2dp_offload.aidl_flag=aidl
persist.bluetooth.dualconnection.supported=true
persist.bluetooth.a2dp_aac_abr.enable=false
persist.bluetooth.bluetooth_audio_hal.disabled=false
persist.bluetooth.sbc_hd_higher_bitrate=1
persist.sys.fflag.override.settings_bluetooth_hearing_aid=true
#test
persist.vendor.bluetooth.connection_improve=yes" >> $PROP
fi

if [ "$STEP11" == "true" ]; then
echo -e "\n #Disable all effects by NLSound Team
ro.audio.ignore_effects=true
ro.vendor.audio.ignore_effects=true
vendor.audio.ignore_effects=true
persist.audio.ignore_effects=true
persis.vendor.audio.ignore_effects=true
persist.sys.phh.disable_audio_effects=1
ro.audio.disable_audio_effects=1
vendor.audio.disable_audio_effects=1
low.pass.filter=Off
midle.pass.filter=Off
high.pass.filter=Off
band.pass.filter=Off
LPF=Off
MPF=Off
HPF=Off
BPF=Off
persist.audio.uhqa=1
persist.vendor.audio.uhqa=1
ro.platform.disable.audiorawout=true
ro.vendor.platform.disable.audiorawout=true
ro.vendor.audio.sfx.speaker=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.scenario=false
ro.vendor.audio.sfx.audiovisual=false
ro.vendor.audio.sfx.independentequalizer=false
vendor.audio.soundfx.usb=false
ro.vendor.audio.soundfx.usb=false
ro.vendor.soundfx.type=none
ro.vendor.audio.soundfx.type=none
persist.sys_phh.disable_audio_effects=1

#add07092023
persist.sys.phh.disable_soundvolume_effect=1
ro.audio.spatializer_enabled=true" >> $PROP
fi

ui_print " "
ui_print "   ######################################## 100% done!"

ui_print " "
ui_print " - All done! With love, NLSound Team. - "
ui_print " "

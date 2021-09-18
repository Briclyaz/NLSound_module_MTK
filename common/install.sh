nlsound() {
case $1 in
	-pre) CONF=pre_processing; XML=preprocess;;
	-post) CONF=output_session_processing; XML=postprocess;;
esac
case $2 in
	*.conf) if [ ! "$(sed -n "/^$CONF {/,/^}/p" $2)" ]; then
		echo -e "\n$CONF {\n    $3 {\n        $4 {\n        }\n    }\n}" >> $2
	elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^    }/p}" $2)" ]; then
		sed -i "/^$CONF {/,/^}/ s/$CONF {/$CONF {\n    $3 {\n        $4 {\n        }\n    }/" $2
	elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^    }/ {/$4 {/,/}/p}}" $2)" ]; then
		sed -i "/^$CONF {/,/^}/ {/$3 {/,/^    }/ s/$3 {/$3 {\n        $4 {\n        }/}" $2
	fi;;
	*.xml) if [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/p" $2)" ]; then     
		sed -i "/<\/audio_effects_conf>/i\    <$XML>\n       <stream type=\"$3\">\n            <apply effect=\"$4\"\/>\n        <\/stream>\n    <\/$XML>" $2
	elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/p}" $2)" ]; then     
		sed -i "/^ *<$XML>/,/^ *<\/$XML>/ s/    <$XML>/    <$XML>\n        <stream type=\"$3\">\n            <apply effect=\"$4\"\/>\n        <\/stream>/" $2
	elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ {/^ *<apply effect=\"$4\"\/>/p}}" $2)" ]; then
		sed -i "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ s/<stream type=\"$3\">/<stream type=\"$3\">\n            <apply effect=\"$4\"\/>/}" $2
	fi;;
esac
}

patch_xml() {
  local Name0=$(echo "$3" | sed -r "s|^.*/.*\[@(.*)=\".*\".*$|\1|")
  local Value0=$(echo "$3" | sed -r "s|^.*/.*\[@.*=\"(.*)\".*$|\1|")
  [ "$(echo "$4" | grep '=')" ] && Name1=$(echo "$4" | sed "s|=.*||") || local Name1="value"
  local Value1=$(echo "$4" | sed "s|.*=||")
  case $1 in
  "-s"|"-u"|"-i")
    local SNP=$(echo "$3" | sed -r "s|(^.*/.*)\[@.*=\".*\".*$|\1|")
    local NP=$(dirname "$SNP")
    local SN=$(basename "$SNP")
    if [ "$5" ]; then
      [ "$(echo "$5" | grep '=')" ] && local Name2=$(echo "$5" | sed "s|=.*||") || local Name2="value"
      local Value2=$(echo "$5" | sed "s|.*=||")
    fi
    if [ "$6" ]; then
      [ "$(echo "$6" | grep '=')" ] && local Name3=$(echo "$6" | sed "s|=.*||") || local Name3="value"
      local Value3=$(echo "$6" | sed "s|.*=||")
    fi
    if [ "$7" ]; then
      [ "$(echo "$7" | grep '=')" ] && local Name4=$(echo "$7" | sed "s|=.*||") || local Name4="value"
      local Value4=$(echo "$7" | sed "s|.*=||")
    fi
  ;;
  esac
  case "$1" in
    "-d") xmlstarlet ed -L -d "$3" "$2";;
    "-u") xmlstarlet ed -L -u "$3/@$Name1" -v "$Value1" "$2";;
    "-s")
      if [ "$(xmlstarlet sel -t -m "$3" -c . "$2")" ]; then
        xmlstarlet ed -L -u "$3/@$Name1" -v "$Value1" "$2"
      else
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      fi;;
    "-i")
      if [ "$(xmlstarlet sel -t -m "$3[@$Name1=\"$Value1\"]" -c . "$2")" ]; then
        xmlstarlet ed -L -d "$3[@$Name1=\"$Value1\"]" "$2"
      fi
      if [ -z "$Value3" ]; then
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -i "$SNP-$MODID" -t attr -n "$Name2" -v "$Value2" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      elif [ "$Value4" ]; then
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -i "$SNP-$MODID" -t attr -n "$Name2" -v "$Value2" \
        -i "$SNP-$MODID" -t attr -n "$Name3" -v "$Value3" \
        -i "$SNP-$MODID" -t attr -n "$Name4" -v "$Value4" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      elif [ "$Value3" ]; then
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -i "$SNP-$MODID" -t attr -n "$Name2" -v "$Value2" \
        -i "$SNP-$MODID" -t attr -n "$Name3" -v "$Value3" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      fi
      ;;
  esac
}

#author - Lord_Of_The_Lost@Telegram
meme_effects() {
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
memes_confxml() {
case $FILE in
	*.conf) sed -i "/$1 {/,/}/d" $FILE
		sed -i "/$2 {/,/}/d" $FILE
		sed -i "s/^effects {/effects {\n  $1 {\n    library $2\n    uuid $5\n  }/g" $FILE
		sed -i "s/^libraries {/libraries {\n  $2 {\n    path $3\/$4\n  }/g" $FILE;;
	*.xml) sed -i "/$1/d" $FILE
		sed -i "/$2/d" $FILE
		sed -i "/<libraries>/ a\        <library name=\"$2\" path=\"$4\"\/>" $FILE
	sed -i "/<effects>/ a\        <effect name=\"$1\" library=\"$2\" uuid=\"$5\"\/>" $FILE;;
esac
}

#author - Lord_Of_The_Lost@Telegram
SET_PERM_RM() {
	SET_PERM_R $MODPATH/$MODID 0 0 0755 0644; [ -d $MODPATH$MIPSB ] && chmod -R 777 $MODPATH$MIPSB; [ -d $MODPATH$MIPSXB ] && chmod -R 777 $MODPATH$MIPSXB; case $1 in -msgdi) UIP "$MSGDI";; esac
}

#author - Lord_Of_The_Lost@Telegram
MOVERPATH() {
if [ $BOOTMODE != true ] && [ -d $MODPATH/$MODID/system_root/system ]; then
		mkdir -p $MODPATH/$MODID/system; cp -rf $MODPATH/$MODID/system_root/system/* $MODPATH/$MODID/system; rm -rf $MODPATH/$MODID/system_root
	fi
if [ -d $MODPATH/$MODID/vendor ]; then
		mkdir -p $MODPATH$MIPSV; cp -rf $MODPATH/$MODID/vendor/* $MODPATH$MIPSV; rm -rf $MODPATH/$MODID/vendor
	fi
if [ $BOOTMODE != true ] && [ -d $MODPATH/$MODID/system/system ]; then
		mkdir -p $MODPATH/$MODID/system; cp -rf $MODPATH/$MODID/system/system/* $MODPATH/$MODID/system; rm -rf $MODPATH/$MODID/system/system
	fi
if [ $BOOTMODE != true ] && [ -d $MODPATH/$MODID/system_root/system/system_ext ]; then
		mkdir -p $MODPATH/$MODID/system/system_ext; cp -rf $MODPATH/$MODID/system_root/system/system_ext/* $MODPATH/$MODID/system/system_ext; rm -rf $MODPATH/$MODID/system_root
	fi
}

[ -f /system/vendor/build.prop ] && BUILDS="/system/build.prop /system/vendor/build.prop" || BUILDS="/system/build.prop"
MTKG90T=$(grep "ro.board.platform=mt6785" $BUILDS)
HELIOG85=$(grep "ro.board.platform=mt6768" $BUILDS)
MT6875=$(grep "ro.board.platform=mt6873" $BUILDS)

RN8PRO=$(grep -E "ro.product.vendor.device=begonia.*|ro.product.vendor.device=begonianin.*" $BUILDS)
R10X4GNOTE9=$(grep -E "ro.product.vendor.device=merlin.*" $BUILDS)
R10XPRO5G=$(grep -E "ro.product.vendor.device=bomb.*" $BUILDS)
R10X5G=$(grep -E "ro.product.vendor.device=atom.*" $BUILDS)

FEATURES=$MODPATH/common/NLSound/features
AUPAR=$MODPATH/common/NLSound/audio_param
CODECS=$MODPATH/common/NLSound/codecs
DSM=$MODPATH/common/NLSound/dsm
NEWDIRAC=$MODPATH/common/NLSound/newdirac

SETC=/system/SETC
SVSETC=/system/vendor/SETC

DEVFEA=/system/etc/device_features/*.xml
DEVFEAA=/vendor/etc/device_features/*.xml

APOS="$(find /system /vendor -type f -name "*AudioParamOptions.xml")"
ADEVS="$(find /system /vendor -type f -name "*audio_device.xml")"
AUEMS="$(find /system /vendor -type f -name "*audio_em.xml")"
AURCONFS="$(find /system /vendor -type f -name "*aurisys_config.xml")"
AURCONFHIFIS="$(find /system /vendor -type f -name "*aurisys_config.xml")"

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

ALL=false

deep_buffer() {
	echo -e '\naudio.deep_buffer.media=false\nvendor.audio.deep_buffer.media=false\nqc.audio.deep_buffer.media=false\nro.qc.audio.deep_buffer.media=false\npersist.vendor.audio.deep_buffer.media=false' >> $MODPATH/system.prop
}

audio_codec() {
	for OAPO in $APOS; do
    APO="$MODPATH$(echo $OAPO | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $APO`
	cp -f $MAGISKMIRROR$OAPO $APO
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
}

audio_device() {
 for OADEV in $ADEVS; do
    ADEV="$MODPATH$(echo $OADEV | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $ADEV`
	cp -f $MAGISKMIRROR$OADEV $ADEV
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
}

audio_parameters() {
 for OAUEM in $AUEMS; do
    AUEM="$MODPATH$(echo $OAUEM | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $AUEM`
	cp -f $MAGISKMIRROR$OAUEM $AUEM
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
}

mtk_bessound() {
 for OAURCONF in $AURCONFS; do
    AURCONF="$MODPATH$(echo $OAURCONF | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $AURCONF`
	cp -f $MAGISKMIRROR$OAURCONF $AURCONF
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
}

device_features_system() {
	for ODEVFEA in $DEVFEA; do 
	DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $DEVFEA`
	cp -f $MAGISKMIRROR$ODEVFEA $DEVFEA
	sed -i 's/\t/  /g' $DEVFEA
		patch_xml -s $DEVFEA '/features/bool[@name="support_a2dp_latency"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_48000"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_96000"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_192000"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_low_latency"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_mid_latency"]' "false"
		patch_xml -s $DEVFEA '/features/bool[@name="support_high_latency"]' "false"
		patch_xml -s $DEVFEA '/features/bool[@name="support_interview_record_param"]' "false"
		patch_xml -s $DEVFEA '/features/bool[@name="support_voip_record"]' "true"
		patch_xml -s $DEVFEA '/features/integer[@name="support_inner_record"]' "1"
		patch_xml -s $DEVFEA '/features/bool[@name="support_hifi"]' "true"
	done
}

device_features_vendor() {
	for ODEVFEAA in $DEVFEAA; do
	DEVFEAA="$MODPATH$(echo $ODEVFEAA | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $DEVFEAA`
	cp -f $MAGISKMIRROR$ODEVFEAA $DEVFEAA
	sed -i 's/\t/  /g' $DEVFEAA
		patch_xml -s $DEVFEAA '/features/bool[@name="support_a2dp_latency"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_samplerate_48000"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_samplerate_96000"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_samplerate_192000"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_low_latency"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_mid_latency"]' "false"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_high_latency"]' "false"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_interview_record_param"]' "false"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_voip_record"]' "true"
		patch_xml -s $DEVFEAA '/features/integer[@name="support_inner_record"]' "1"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_hifi"]' "true"
	done
}

audio_param() {
  cp -f $MAGISKMIRROR$AUPAR $MODPATH/system/etc/
}

dsp_hal() {
	for OAURCONFHIFI in $AURCONFHIFIS; do
	AURCONFHIFI="$MODPATH$(echo $OAURCONFHIFI | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $AURCONFHIFI`
	cp -f $MAGISKMIRROR$OAURCONFHIFI $AURCONFHIFI
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
}

media_codecs() {
	cp -f $MAGISKMIRROR$CODECS/media_codecs_mediatek_audio.xml $MODPATH/system/vendor/etc/media_codecs_mediatek_audio.xml
	cp -f $MAGISKMIRROR$CODECS/media_codecs_mediatek_audio.xml $MODPATH/vendor/etc/media_codecs_mediatek_audio.xml
}

dsm_configs() {
	cp -f $MAGISKMIRROR$DSM/DSM_config.xml $MODPATH/system/vendor/etc/DSM_config.xml
	cp -f $MAGISKMIRROR$DSM/DSM.xml $MODPATH/system/vendor/etc/DSM.xml
	cp -f $MAGISKMIRROR$DSM/DSM_config.xml $MODPATH/vendor/etc/DSM_config.xml
	cp -f $MAGISKMIRROR$DSM/DSM.xml $MODPATH/vendor/etc/DSM.xml
}

dirac() {
	for OFILE in $CFGS; do
	FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $FILE`
	cp -f $MAGISKMIRROR$OFILE $FILE
		meme_effects $FILE
		memes_confxml "dirac_gef" "$MODID" "\/system\/lib\/soundfx" "libdiraceffect.so" "3799d6d1-22c5-43c3-b3ec-d664cf8d2f0d"
		nlsound -post "$FILE" "music" "dirac_gef"
	done
	mkdir -p $MODPATH/system/vendor/etc/dirac $MODPATH/system/vendor/lib/rfsa/adsp $MODPATH/system/vendor/lib/soundfx
	cp -f $NEWDIRAC/diracvdd.bin $MODPATH/system/vendor/etc/
	cp -f $NEWDIRAC/interfacedb $MODPATH/system/vendor/etc/dirac
	cp -f $NEWDIRAC/dirac_resource.dar $MODPATH/system/vendor/lib/rfsa/adsp
	cp -f $NEWDIRAC/dirac.so $MODPATH/system/vendor/lib/rfsa/adsp
	cp -f $NEWDIRAC/libdirac-capiv2.so $MODPATH/system/vendor/lib/rfsa/adsp
	cp -f $NEWDIRAC/libdiraceffect.so $MODPATH/system/vendor/lib/soundfx
echo -e "\n# Patch Dirac
persist.dirac.acs.controller=gef
persist.dirac.gef.oppo.syss=true
persist.dirac.config=64
persist.dirac.gef.exs.did=29,49
persist.dirac.gef.ext.did=10,20,29,49
persist.dirac.gef.ins.did=19,134,150
persist.dirac.gef.int.did=15,19,134,150
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
persist.dirac.acs.ignore_error=1" >> $MODPATH/system.prop
}

prop() {
echo -e "\n#"
echo -e "\n#PROP TWEAKS BY NLSOUND TEAM"
echo -e "\n#
# Spv_avs

persist.vendor.audio.spv4.enable=true
persist.vendor.audio.avs.afe_api_version=9

# Media_codecs

ro.mediacodec.min_sample_rate=7350
ro.mediacodec.max_sample_rate=2822400
vendor.audio.flac.sw.decoder.24bit=true
vendor.audio.aac.sw.decoder.24bit=true
vendor.audio.use.sw.alac.decoder=true
vendor.audio.flac.sw.encoder.24bit=true
vendor.audio.aac.sw.encoder.24bit=true
vendor.audio.use.sw.ape.decoder=true
vendor.audio.vorbis.complexity.default=8
vendor.audio.vorbis.quality=100
vendor.audio.aac.complexity.default=8
vendor.audio.aac.quality=100
media.stagefright.enable-player=true
media.stagefright.enable-http=true
media.stagefright.enable-aac=true
media.stagefright.enable-qcp=true
media.stagefright.enable-fma2dp=true
media.stagefright.enable-scan=true
media.stagefright.audio.sink=128
vendor.audio.tunnel.encode=true
tunnel.audio.encode=true
qc.tunnel.audio.encode=true
audio.decoder_override_check=true
use.non-omx.mp3.decoder=false
use.non-omx.aac.decoder=false
mpq.audio.decode=true
audio.nat.codec.enabled=1
media.aac_51_output_enabled=true

# LPA

lpa.decode=false
lpa.use-stagefright=false
lpa.releaselock=false
lpa30.decode=false

# Offload

vendor.av.offload.enable=true
av.offload.enable=true
qc.av.offload.enable=true
audio.offload.buffer.size.kb=32

# AF

af.thread.throttle=0
af.fast.track.multiplier=2
ro.af.client_heap_size_kbyte=7168

# Features

vendor.audio.feature.external_dsp.enable=true
vendor.audio.feature.external_speaker.enable=true
vendor.audio.feature.external_speaker_tfa.enable=true
vendor.audio.feature.ext_hw_plugin=true
vendor.audio.feature.ras.enable=true
vendor.audio.feature.src_trkn.enable=true
vendor.audio.feature.kpi_optimize.enable=true
vendor.audio.feature.power_mode.enable=true 
vendor.audio.feature.compress_meta_data.enable=false
vendor.audio.feature.compr_cap.enable=false
vendor.audio.feature.compress_in.enable=false
vendor.audio.feature.dynamic_ecns.enable=true
vendor.audio.feature.concurrent_capture.enable=true
vendor.audio.feature.devicestate_listener.enable=false
vendor.audio.feature.thermal_listener.enable=false

# Effects

persist.vendor.audio.ambisonic.auto.profile=true
effect.reverb.pcm=1
vendor.audio.safx.pbe.enabled=true
ro.vendor.audio.sfx.speaker=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.scenario=false
ro.vendor.audio.surround.support=true
ro.vendor.audio.scenario.support=true

# Hi-Fi

ro.audio.hifi=true
persist.audio.hifi=true
persist.audio.hifi.volume=72
persist.vendor.audio.hifi=true
persist.audio.hifi.int_codec=true
vendor.audio.feature.hifi_audio.enable=true
ro.vendor.audio.hifi=true
persist.vendor.audio.hifi.int_codec=true
ro.hardware.hifi.support=true

# Audio_hal

vendor.audio_hal.in_period_size=144
vendor.audio_hal.period_multiplier=3 
vendor.audio.hal.output.suspend.supported=true

# Playback

vendor.audio.playback.dsp.pathdelay=0
audio.playback.mch.downsample=false
vendor.audio.playback.mch.downsample=false
persist.vendor.audio.playback.mch.downsample=false

# MM

persist.mm.enable.prefetch=true
mm.enable.smoothstreaming=true
vendor.audio.parser.ip.buffer.size=262144
vendor.mm.enable.qcom_parser=63963135
persist.mm.enable.prefetch=true

# Recording

ro.vendor.audio.sdk.ssr=false
ro.ril.enable.amr.wideband=1
persist.audio.lowlatency.rec=true
ro.vendor.audio.recording.hd=true

# Other_shit
vendor.audio.matrix.limiter.enable=0
vendor.audio.enable.mirrorlink=false
vendor.audio.feature.afe_proxy.enable=true
persist.vendor.audio.ha_proxy.enabled=true
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.tfa9874.dsp.enabled=true
persist.vendor.audio_hal.dsp_bit_width_enforce_mode=24
persist.vendor.audio.format.24bit=true
vendor.audio.snd_card.open.retries=50
persist.vendor.audio.hw.binder.size_kbyte=1024
persist.vendor.audio.bcl.enabled=false
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.power.pasr.enabled=true
ro.vendor.audio.multiroute=true
vendor.audio.spkr_prot.tx.sampling_rate=48000
ext.spkr.enabled=true" >> $MODPATH/system.prop
}

improve_bluetooth() {
echo -e "\n# Bluetooth

persist.service.btui.use_aptx=1
persist.bt.enableAptXHD=true
persist.bt.a2dp.aptx_disable=false
persist.bt.a2dp.aptx_hd_disable=false
persist.vendor.btstack.enable.splita2dp=true 
persist.vendor.btstack.enable.twsplus=true
persist.vendor.btstack.connect.peer_earbud=true
persist.vendor.btstack.enable.twsplussho=true
persist.vendor.btstack.enable.swb=true
persist.vendor.btstack.enable.swbpm=true
persist.vendor.btstack.avrcp.pos_time=1000
persist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true 
persist.vendor.qcom.bluetooth.enable.splita2dp=true 
persist.vendor.qcom.bluetooth.twsp_state.enabled=false
persist.vendor.qcom.bluetooth.scram.enabled=false
persist.vendor.qcom.bluetooth.aac_vbr_ctl.enabled=true
persist.vendor.qcom.bluetooth.aptxadaptiver2_1_support=true
persist.vendor.qcom.bluetooth.enable.swb=true
persist.bt.a2dp.aac_disable=false
audio.effect.a2dp.enable=1
vendor.audio.effect.a2dp.enable=1
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.bt.a2dp.addr_check_enabled_for_aac=true
persist.vendor.bt.soc.scram_freqs=192
persist.vendor.bt.aac_frm_ctl.enabled=true
persist.vendor.bt.aac_vbr_frm_ctl.enabled=true
vendor.bt.pts.pbap=true
ro.bluetooth.emb_wp_mode=false
ro.bluetooth.wipower=false 
ro.vendor.bluetooth.wipower=false
persist.bluetooth.enabledelayreports=true
persist.sys.fflag.override.settings_bluetooth_hearing_aid=true
persist.bt.sbc_hd_enabled=1
persist.bluetooth.sbc_hd_higher_bitrate=1" >> $MODPATH/system.prop
}

AUTO_EN() {
	ui_print " "
    ui_print " - You selected AUTO installation mode - "
    AUTO_In=true
	
	ui_print " "
	ui_print " - The installation has started! - "
	
	ui_print " "
	ui_print "     Please wait until it is completed. "
	ui_print "     The installation time can vary from "
	ui_print "     one minute to ten minutes depending "
	ui_print "     on your device and the ROM used "
   
    if [ $AUTO_In = true ]; then
		deep_buffer
	fi
	
	if [ $AUTO_In = true ]; then
		audio_codec
	fi
 
    ui_print " "
    ui_print "   ########================================= 20% done!"
	
	if [ $AUTO_In = true ]; then
		mtk_bessound
	fi
	
	ui_print " "
    ui_print "   ##################====================== 45% done!"
	
	if [ $AUTO_In = true ]; then
		audio_codec
	fi
	
	ui_print " "
    ui_print "   ########################================ 60% done!"
	
	if [ $AUTO_In = true ]; then
      if [ -f /$sys_tem/etc/device_features/*.xml ]; then
		device_features_system
      elif [ -f /$sys_tem/vendor/etc/device_features/*.xml ]; then
        device_features_vendor
      fi
	fi
	
	if [ $AUTO_In = true ]; then
		media_codecs
	fi
	
	ui_print " "
    ui_print "   ######################################## 100% done!"
	
	ui_print " "
	ui_print " - All done! "
}

AUTO_RU() {
	ui_print " "
	ui_print " - Вы выбрали режим установки АВТО - "
    AUTO_In=true
	
	ui_print " "
	ui_print " - Установка началась! - "
	
	ui_print " "
	ui_print "     Пожалуйста дождитесь завершения. "
	ui_print "     Время установки может варьироваться "
	ui_print "     от одной до пяти минут в зависимости от "
	ui_print "     вашего устройства и используемой прошивки. "
   
	if [ $AUTO_In = true ]; then
		deep_buffer
	fi
	
	if [ $AUTO_In = true ]; then
		audio_codec
	fi
 
    ui_print " "
    ui_print "   ########================================= 20% done!"
	
	if [ $AUTO_In = true ]; then
		mtk_bessound
	fi
	
	ui_print " "
    ui_print "   ##################====================== 45% done!"
	
	if [ $AUTO_In = true ]; then
		audio_codec
	fi
	
	ui_print " "
    ui_print "   ########################================ 60% done!"
	
	if [ $AUTO_In = true ]; then
      if [ -f /$sys_tem/etc/device_features/*.xml ]; then
		device_features_system
      elif [ -f /$sys_tem/vendor/etc/device_features/*.xml ]; then
        device_features_vendor
      fi
	fi
	
	if [ $AUTO_In = true ]; then
		media_codecs
	fi
	
	ui_print " "
    ui_print "   ######################################## 100% готово!"
	
	ui_print " "
	ui_print " - Всё готово! "
}

English() { 
	  ENG_CHK=1
	  ui_print " "
	  ui_print " - You selected English language! -"
	  ui_print " "
	  ui_print " - Select installation mode: "
	  ui_print " "
	  ui_print " - NOTE: [VOL+] - select, [VOL-] - confirm "
	  ui_print " "
	  ui_print " 1. Auto (Only the most necessary things"
	  ui_print "    for your device will be installed)"
	  ui_print " "
	  ui_print " 2. Manual (You configure the module yourself)"
	  ui_print " "
	  ui_print " "
	  ui_print " 3. Install all (For experienced users, may cause problems)"
	  ui_print " "
	  ui_print "        Selected: "
	  ui_print " "
	  
	  while true; do
	  ui_print "------>    $ENG_CHK    step"
	  ui_print " "
	  if $VKSEL; then
		ENG_CHK=$((ENG_CHK + 1))
		ALL=true
	  else
		break
	  fi
		
	  if [ $ENG_CHK -gt 3 ]; then
		ENG_CHK=1
	  fi
done

case $ENG_CHK in
	1) AUTO_EN;;
	2) ENG_Manual;;
	3) All_En;;
esac
}

Russian() {  
	  RU_CHK=1
	  ui_print " "
	  ui_print " - Вы выбрали Русский язык! -"
	  ui_print " "
	  ui_print " - Выберите режим установки: "
	  ui_print " "
	  ui_print " - Заметка: [VOL+] - выбор, [VOL-] - подтверждение "
	  ui_print " "
	  ui_print " 1. Авто (Только самое необходимое для"
	  ui_print "    вашего устройства будет установлено)"
	  ui_print " "
	  ui_print " 2. Ручной (Вы самостоятельно настраиваете модуль)"
	  ui_print " "
	  ui_print " "
	  ui_print " 3. Установить всё (Для опытных пользователей, может вызвать проблемы)"
	  ui_print " "
	  ui_print "        Выбран: "
	  ui_print " "
	  while true; do
	  ui_print "------>    $RU_CHK    пункт"
	  ui_print " "
	  if $VKSEL; then
		RU_CHK=$((RU_CHK + 1))
		ALL=true
	  else
		break
	  fi
		
	  if [ $RU_CHK -gt 3 ]; then
		RU_CHK=1
	  fi
done

case $RU_CHK in
	1) AUTO_RU;;
	2) RU_Manual;;
	3) All_Ru;;
esac
}
	
ENG_Manual() {
		ui_print " "
		ui_print " - You selected English language! -"
		ui_print " "
		ui_print " - Configurate me, pls >.< -"
		ui_print " "
			
		ui_print " "
		ui_print " - Disable Deep Buffer -"
		ui_print "***************************************************"
		ui_print "* [1/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*               This option disable               *"
		ui_print "*            deep buffer in your device.          *"
		ui_print "*         If you want more low frequencies,       *"
		ui_print "*                skip this option.                *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Disable deep buffer?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
				STEP1=true
		fi

		ui_print " "
		ui_print " - New audio parameters in interal audio codec -"
		ui_print "***************************************************"
		ui_print "* [2/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*             This option configure               *"
		ui_print "*            your interal audio codec             *"
		ui_print "*       of this option may cause no sound!        *"
		ui_print "*             [RECOMMENDED INSTALL]               *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Install new audio parameters in interal audio codec?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP2=true
		fi

		ui_print " "
		ui_print " - Audio device patches -"
		ui_print "***************************************************"
		ui_print "* [3/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*             This option configure               *"
		ui_print "*            your interal audio codec             *"
		ui_print "*       of this option may cause no sound!        *"
		ui_print "*             [RECOMMENDED INSTALL]               *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Install audio device patches?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP3=true
		fi

		ui_print " "
		ui_print " - New audio parameters -"
		ui_print "***************************************************"
		ui_print "* [4/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*       This option applies new perameters        *"
		ui_print "*          to your device's audio codec.          *"
		ui_print "*              May cause problems.                *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Install new audio parameters?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP4=true
		fi

		ui_print " "
		ui_print " - Configure MediaTek Bessound -"
		ui_print "***************************************************"
		ui_print "* [5/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*     This option configure MediaTek Bessound     *"
		ui_print "*          technology in your device.             *"
		ui_print "*              May cause problems.                *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Configuration?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP5=true
		fi

		ui_print " "
		ui_print " - Patch device_features files -"
		ui_print "***************************************************"
		ui_print "* [6/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*        This step will do the following:         *"
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
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Configuration?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP6=true
		fi

		ui_print " "
		ui_print " - Patch audio_param options -"
		ui_print "***************************************************"
		ui_print "* [7/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*        This step improve audio parameters       *"
		ui_print "*           in your internal audio codec.         *"
		ui_print "*                May case problem.                *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Patch?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP7=true
		fi

		ui_print " "
		ui_print " - Configure DSP HAL -"
		ui_print "***************************************************"
		ui_print "* [8/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*      This option configure DSP HAL libs         *"
		ui_print "*          technology in your device.             *"
		ui_print "*              May cause problems.                *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Configuration?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP8=true
		fi

		ui_print " "
		ui_print " - Patch media codecs -"
		ui_print "***************************************************"
		ui_print "* [9/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*        This step patching media codecs          *"
		ui_print "*     in your system for improving quality.       *"
		ui_print "*         Recommended for installation.           *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Patch?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP9=true
		fi

		ui_print " "
		ui_print " - Patch DSM Configs -"
		ui_print "***************************************************"
		ui_print "* [10/10]                                         *"
		ui_print "*                                                 *"
		ui_print "*        This step patching DSM files             *"
		ui_print "*     in your system for improving quality.       *"
		ui_print "*         Recommended for installation.           *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Patch?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP10=true
		fi
		
		ui_print " "
		ui_print " - Add new Dirac -"
		ui_print "***************************************************"
		ui_print "* [11/13]                                         *"
		ui_print "*                                                 *"
		ui_print "*    This step added new Dirac in your system     *"
		ui_print "*             May cause problems.                 *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Add?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP11=true
		fi
		
		ui_print " "
		ui_print " - Install tweaks in prop file - "
		ui_print "***************************************************"
		ui_print "* [12/13]                                         *"
		ui_print "*                                                 *"
		ui_print "*    This option will change the sound quality    *"
		ui_print "*                  the most.                      *"
		ui_print "*             May cause problems.                 *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Install?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
		  STEP12=true
		fi
		
		ui_print " "
		ui_print " - Improve Bluetooth - "
		ui_print "***************************************************"
		ui_print "* [13/13]                                         *"
		ui_print "*                                                 *"
		ui_print "*   This option will improve the audio quality    *"
		ui_print "*    in Bluetooth, as well as fix the problem     *"
		ui_print "*      of disappearing the AAC codec switch       *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Install?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
		  STEP13=true
		fi
		
		ui_print " "
		ui_print " - Processing. . . . -"
		ui_print " "
		ui_print " - You can minimize Magisk and use the device -"
		ui_print " - and then come back here to reboot and apply the changes. -"

		if [ $STEP1 = true ]; then
			deep_buffer
		fi

		if [ $STEP2 = true ]; then
			audio_codec
		fi

		ui_print " "
		ui_print "   ########================================ 20% ready!"

		if [ $STEP3 = true ]; then
			audio_device
		fi

		if [ $STEP4 = true ]; then
			audio_parameters
		fi

		ui_print " "
		ui_print "   ################======================== 40% ready!"

		if [ $STEP5 = true ]; then
			mtk_bessound
		fi

		if [ $STEP6 = true ]; then
			if [ -f $DEVFEA ]; then
			device_features_system
		  elif [ -f $DEVFEAA ]; then
			device_features_vendor
		  fi
		fi

		ui_print " "
		ui_print "   ########################================ 60% ready!"

		if [ $STEP7 = true ]; then
			audio_param
		fi

		if [ $STEP8 = true ]; then
			dsp_hal
		fi

		ui_print " "
		ui_print "   ################################======== 80% ready!"

		if [ $STEP9 = true ]; then
			media_codecs
		fi

		if [ $STEP10 = true ]; then
			dsm_configs
		fi
		
		if [ $STEP11 = true ]; then
			dirac
		fi
		
		if [ $STEP12 = true ]; then
			prop
		fi
	
		if [ $STEP13 = true ]; then
			improve_bluetooth
		fi
		
		SET_PERM_RM
		MOVERPATH
		
		ui_print " "
		ui_print "   ######################################## 100% done!"
		
		ui_print " "
		ui_print " - All done! With love, NLSound Team. - "
		ui_print " "
}

RU_Manual() {
		ui_print " - Вы выбрали русский язык! -"
		ui_print " "
		ui_print " - Настрой меня, пожалуйста >.< -"
		ui_print " "
		ui_print " "
		ui_print " - Отключить глубокий буфер. -"
		ui_print "*************************************************"
		ui_print "* [1/10]                                        *"
		ui_print "*                                               *"
		ui_print "*               Эта опция отключит              *"
		ui_print "*        глубокий буфер в вашем устройстве.     *"
		ui_print "*     Если вы ощущаете нехватку низких частот,  *"
		ui_print "*             и пропустите эту опцию.           *"
		ui_print "*                                               *"
		ui_print "*************************************************"
		ui_print "   Отключить глубокий буфер?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
			STEP1=true
		fi	

		ui_print " "
		ui_print " - Новые аудио параметры для внутреннего аудио кодека -"
		ui_print "***************************************************"
		ui_print "* [2/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*            Эта опция сконфигурирует             *"
		ui_print "*           ваш внутренний аудио кодек.           *"
		ui_print "*          [Рекомендуется для установки]          *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Установить новые параметры для внутреннего аудио кодека?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		   STEP2=true
		fi

		ui_print " "
		ui_print " - Audio device патчи -"
		ui_print "***************************************************"
		ui_print "* [3/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*            Эта опция сконфигурирует             *"
		ui_print "*           ваш внутренний аудио кодек.           *"
		ui_print "*          [Рекомендуется для установки]          *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Установить audio device патчи?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		  STEP3=true
		fi

		ui_print " "
		ui_print " - Новые аудио параметры-"
		ui_print "*************************************************"
		ui_print "* [4/10]                                        *"
		ui_print "*                                               *"
		ui_print "*   Эта опция применит новые аудио параметры    *"
		ui_print "*      для вашего внутреннего аудио кодека      *"
		ui_print "*           Может вызвать проблемы.             *"
		ui_print "*                                               *"
		ui_print "*************************************************"
		ui_print "   Установить новые аудио параметры?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		   STEP4=true
		fi

		ui_print " "
		ui_print " - Конфигурация MediaTek Bessound -"
		ui_print "***************************************************"
		ui_print "* [5/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*   Эта опция сконфигурирует MediaTek Bessound    *"
		ui_print "*        технологию в вашем устройстве.           *"
		ui_print "*           Может вызвать проблемы.               *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Сконфигурировать?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		   STEP5=true
		fi

		ui_print " "
		ui_print " - Патчинг device_features файлов -"
		ui_print "*************************************************"
		ui_print "* [6/10]                                        *"
		ui_print "*                                               *"
		ui_print "*        Этот пункт сделает следующее:          *"
		ui_print "*        - Разблокирует частоту семплирования   *"
		ui_print "*          аудио вплоть до 384000 кГц;          *"
		ui_print "*        - Активирует переключатель ААС кодека  *"
		ui_print "*          в настройках Bluetooth-наушников;    *"
		ui_print "*        - Активирует поддержку ИИР параметров; *"
		ui_print "*        - Активирует поддержку стерео записи;  *"
		ui_print "*        - Активирует поддержку HD записи;      *"
		ui_print "*        - Активирует поддержку Dolby и Hi-Fi   *"
		ui_print "*          (на полдерживаемых устройствах);     *"
		ui_print "*        - Активирует поддержку аудио фокуса    *"
		ui_print "*          при записи видео;                    *"
		ui_print "*        - Активирует поддержку быстрого        *"
		ui_print "*          подключения к Bluetooth наушникам.   *"
		ui_print "*                                               *"
		ui_print "*  И многое другое . . .                        *"
		ui_print "*                                               *"
		ui_print "*************************************************"
		ui_print "   Установить?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		  STEP6=true
		fi

		ui_print " "
		ui_print " - Патчинг audio_param опций -"
		ui_print "*************************************************"
		ui_print "* [7/10]                                        *"
		ui_print "*                                               *"
		ui_print "*   Этот пункт улучшит настройки аудио пар-ов   *"
		ui_print "*        вашего внутреннего аудио кодека        *"
		ui_print "*            Может вызвать проблемы.            *"
		ui_print "*                                               *"
		ui_print "*************************************************"
		ui_print "   Патчить?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		   STEP7=true
		fi

		ui_print " "
		ui_print " - Сконфигурировать DSP HAL -"
		ui_print "***************************************************"
		ui_print "* [8/10]                                          *"
		ui_print "*                                                 *"
		ui_print "*   Эта опция настроит DSP HAL библиотеки         *"
		ui_print "*        в системе вашего устройства.             *"
		ui_print "*          Может вызвать проблемы.                *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Конфигурировать?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		  STEP8=true
		fi

		ui_print " "
		ui_print " - Патчинг media codecs -"
		ui_print "*************************************************"
		ui_print "* [9/10]                                        *"
		ui_print "*                                               *"
		ui_print "*    Эта опция настроит медиа кодеки в вашей    *"
		ui_print "*     системе для повышения качества аудио.     *"
		ui_print "*         [Рекомендуется для установки]         *"
		ui_print "*                                               *"
		ui_print "*************************************************"
		ui_print "   Патчить?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		  STEP9=true
		fi

		ui_print " "
		ui_print " - Патчинг DSM конфигов -"
		ui_print "*************************************************"
		ui_print "* [10/10]                                       *"
		ui_print "*                                               *"
		ui_print "*    Этот пункт пропатчит DSM файлы в вашей     *"
		ui_print "*     системе для повышения качества аудио      *"
		ui_print "*         [Рекомендуется для установки]         *"
		ui_print "*                                               *"
		ui_print "*************************************************"
		ui_print "   Патчить?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		  STEP10=true
		fi
		
		ui_print " "
		ui_print " - Добавить новый Dirac -"
		ui_print "***************************************************"
		ui_print "* [10/10]                                         *"
		ui_print "*                                                 *"
		ui_print "* Этот пункт добавит новый Dirac в вашу систему.  *"
		ui_print "*         Может вызвать проблемы.                 *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Добавить?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = YES, Vol Down = NO"
		if chooseport; then
			STEP11=true
		fi
		
		ui_print " "
		ui_print " - Установить твики в prop файл - "
		ui_print "***************************************************"
		ui_print "* [11/13]                                         *"
		ui_print "*                                                 *"
		ui_print "*  Эта опция сильнее всех изменит качество звука  *"
		ui_print "*          Может вызвать проблемы.                *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Установить?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		  STEP12=true
		fi
		
		ui_print " "
		ui_print " - Улучшить Bluetooth - "
		ui_print "***************************************************"
		ui_print "* [13/13]                                         *"
		ui_print "*                                                 *"
		ui_print "*        Эта опция улучшит качество аудио         *"
		ui_print "*     в Bluetooth, а также исправит проблему с    *"
		ui_print "*      исчезновением переключателя ААС кодека.    *"
		ui_print "*            Может вызвать проблемы.              *"
		ui_print "*                                                 *"
		ui_print "***************************************************"
		ui_print "   Установить?"
		sleep 1
		ui_print " "
		ui_print "   Vol Up = ДА, Vol Down = НЕТ"
		if chooseport; then
		  STEP13=true
		fi
		
		ui_print " "
		ui_print " - Обработка. . . . -"
		ui_print " "
		ui_print " - Вы можете свернуть Magisk и пользоваться устройством -"
		ui_print " - а затем вернуться сюда для перезагрузки и применения изменений. -"

		if [ $STEP1 = true ]; then
			deep_buffer
		fi

		if [ $STEP2 = true ]; then
			audio_codec
		fi

		ui_print " "
		ui_print "   ########================================ 20% готово!"

		if [ $STEP3 = true ]; then
			audio_device
		fi

		if [ $STEP4 = true ]; then
			audio_parameters
		fi

		ui_print " "
		ui_print "   ################======================== 40% готово!"

		if [ $STEP5 = true ]; then
			mtk_bessound
		fi

		if [ $STEP6 = true ]; then
			if [ -f $DEVFEA ]; then
			device_features_system
		  elif [ -f $DEVFEAA ]; then
			device_features_vendor
		  fi
		fi

		ui_print " "
		ui_print "   ########################================ 60% готово!"

		if [ $STEP7 = true ]; then
			audio_param
		fi

		if [ $STEP8 = true ]; then
			dsp_hal
		fi

		ui_print " "
		ui_print "   ################################======== 80% готово!"

		if [ $STEP9 = true ]; then
			media_codecs
		fi

		if [ $STEP10 = true ]; then
			dsm_configs
		fi
		
		if [ $STEP11 = true ]; then
			dirac
		fi
		
		if [ $STEP12 = true ]; then
			prop
		fi
	
		if [ $STEP13 = true ]; then
			improve_bluetooth
		fi
		
		SET_PERM_RM
		MOVERPATH
		
		ui_print " "
		ui_print " - Всё готово! С любовью, NLSound Team. -"
		ui_print " "
}

All_En() {
	ui_print " "
	ui_print " - You selected INSTALL ALL "
	ui_print " "
	ui_print " - Installation started! Please, wait..."
	
	if [ $ALL = true ]; then
		deep_buffer
		audio_codec
		audio_device
		audio_parameters	
		mtk_bessound
		
		if [ -f /$sys_tem/etc/device_features/*.xml ]; then
			device_features_system
		else
			device_features_vendor
		fi
		
		audio_param
		dsp_hal
		media_codecs
		dsm_configs
		prop
		improve_bluetooth
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
	ui_print " All done!"
}

All_Ru() {
	ui_print " "
	ui_print " - Вы выбрали УСТАНОВИТЬ ВСЁ "
	ui_print " "
	ui_print " - Установка начата! Пожалуйста, подождите..."
	
	if [ $ALL = true ]; then
		deep_buffer
		audio_codec
		audio_device
		audio_parameters	
		mtk_bessound
		
		if [ -f /$sys_tem/etc/device_features/*.xml ]; then
			device_features_system
		else
			device_features_vendor
		fi
		
		audio_param
		dsp_hal
		media_codecs
		dsm_configs
		prop
		improve_bluetooth
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
	ui_print " Всё готово!"
}

ui_print " "
ui_print " - Select language -"
ui_print " "
ui_print " - NOTE: [VOL+] - select, [VOL-] - confirm "
sleep 1
LANG=1
ui_print " "
ui_print "   1. English "
ui_print "   2. Русский "
ui_print " "
ui_print "      Selected: "
while true; do
	ui_print "      $LANG"
	if $VKSEL; then
		LANG=$((LANG + 1))
	else
		break
	fi
		
	if [ $LANG -gt 2 ]; then
		LANG=1
	fi
done

case $LANG in
	1) English;;
	2) Russian;;
esac


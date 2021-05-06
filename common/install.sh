set_perm() {
	chown $1:$2 $4
	chmod $3 $4
	case $4 in
		*/vendor/etc/*)
			chcon 'u:object_r:vendor_configs_file:s0' $4
		;;
		*/vendor/*)
			chcon 'u:object_r:vendor_file:s0' $4
		;;
		*/data/adb/*.d/*)
			chcon 'u:object_r:adb_data_file:s0' $4
		;;
		*)
			chcon 'u:object_r:system_file:s0' $4
		;;
	esac
}

cp_perm() {
  if [ -f "$4" ]; then
    rm -f $5
    cat $4 > $5
    set_perm $1 $2 $3 $5
  fi
}

set_perm_recursive() {
	find $5 -type d | while read dir; do
		set_perm $1 $2 $3 $dir
	done
	find $5 -type f -o -type l | while read file; do
		set_perm $1 $2 $4 $file
	done
}

nlsound() {
  case $1 in
    *.conf) SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *music {/p}" $1 | sed -r "s/( *).*/\1/")
            EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\music {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
            for EFFECT in ${EFFECTS}; do
              SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
              [ "$EFFECT" != "atmos" ] && sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/ s/^/#/g}" $1
            done;;
     *.xml) EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"music\">$/,/^ *<\/stream>$/ {/<stream type=\"music\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
            for EFFECT in ${EFFECTS}; do
              [ "$EFFECT" != "atmos" ] && sed -ri "s/^( *)<apply effect=\"$EFFECT\"\/>/\1<\!--<apply effect=\"$EFFECT\"\/>-->/" $1
            done;;
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

[ -f /system/vendor/build.prop ] && BUILDS="/system/build.prop /system/vendor/build.prop" || BUILDS="/system/build.prop"
MTKG90T=$(grep "ro.board.platform=mt6785" $BUILDS)
HELIOG85=$(grep "ro.board.platform=mt6768" $BUILDS)
MT6875=$(grep "ro.board.platform=mt6873" $BUILDS)

RN8PRO=$(grep -E "ro.product.vendor.device=begonia.*|ro.product.vendor.device=begonianin.*" $BUILDS)
R10X4GNOTE9=$(grep -E "ro.product.vendor.device=merlin.*" $BUILDS)
R10XPRO5G=$(grep -E "ro.product.vendor.device=bomb.*" $BUILDS)
R10X5G=$(grep -E "ro.product.vendor.device=atom.*" $BUILDS)

NLS=$MODPATH/common/NLSound
FEATURES=$MODPATH/common/NLSound/features
AUPAR=$MODPATH/common/NLSound/audio_param
CODECS=$MODPATH/common/NLSound/codecs
DSM=$MODPATH/common/NLSound/dsm

SETC=/system/SETC
SVSETC=/system/vendor/SETC

DEVFEA=/system/etc/device_features/*.xml
DEVFEAA=/vendor/etc/device_features/*.xml

APOS="$(find /system /vendor -type f -name "*AudioParamOptions.xml")"
ADEVS="$(find /system /vendor -type f -name "*audio_device.xml")"
AUEMS="$(find /system /vendor -type f -name "*audio_em.xml")"
AURCONFS="$(find /system /vendor -type f -name "*aurisys_config.xml")"
AURCONFHIFIS="$(find /system /vendor -type f -name "*aurisys_config.xml")"

mkdir -p $MODPATH/tools
cp -f $MODPATH/common/addon/External-Tools/tools/$ARCH32/* $MODPATH/tools/
chmod -R 0755 $MODPATH/tools

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

deep_buffer() {
  echo -e '\naudio.deep_buffer.media=false\nvendor.audio.deep_buffer.media=false\nqc.audio.deep_buffer.media=false\nro.qc.audio.deep_buffer.media=false\npersist.vendor.audio.deep_buffer.media=false' >> $MODPATH/system.prop
}

audio_codec() {
 for OAPO in ${APOS}; do
    APO="$MODPATH$(echo $OAPO | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OAPO $APO
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
 for OADEV in ${ADEVS}; do
    ADEV="$MODPATH$(echo $OADEV | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OADEV $ADEV
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
 for OAUEM in ${AUEMS}; do
    AUEM="$MODPATH$(echo $OAUEM | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OAUEM $AUEM
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
 for OAURCONF in ${AURCONFS}; do
    AURCONF="$MODPATH$(echo $OAURCONF | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OAURCONF $AURCONF
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
	for ODEVFEA in ${DEVFEA}; do 
		DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g")"
		cp_ch $ORIGDIR$ODEVFEA $DEVFEA
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
	for ODEVFEAA in ${DEVFEAA}; do 
		DEVFEAA="$MODPATH$(echo $ODEVFEAA | sed "s|^/vendor|/system/vendor|g")"
		cp_ch $ORIGDIR$ODEVFEAA $DEVFEAA
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
  cp_ch -f $AUPAR $MODPATH/system/etc/
}

dsp_hal() {
  for OAURCONFHIFI in ${AURCONFHIFIS}; do
    AURCONFHIFI="$MODPATH$(echo $OAURCONFHIFI | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OAURCONFHIFI $AURCONFHIFI
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
   cp_ch -f $CODECS/media_codecs_mediatek_audio.xml $MODPATH/system/vendor/etc/media_codecs_mediatek_audio.xml
   cp_ch -f $CODECS/media_codecs_mediatek_audio.xml $MODPATH/vendor/etc/media_codecs_mediatek_audio.xml
}

dsm_configs() {
 cp_ch -f $DSM/DSM_config.xml $MODPATH/system/vendor/etc/DSM_config.xml
 cp_ch -f $DSM/DSM.xml $MODPATH/system/vendor/etc/DSM.xml
 cp_ch -f $DSM/DSM_config.xml $MODPATHvendor/etc/DSM_config.xml
 cp_ch -f $DSM/DSM.xml $MODPATH/vendor/etc/DSM.xml
}

ui_print " "
ui_print " - Select language -"
sleep 1
ui_print " "
ui_print "   Vol Up = English, Vol Down = Русский"
if chooseport; then
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
    ui_print " "
    ui_print " - All done! With love, NLSound Team. -"
    ui_print " "
else
    ui_print " "
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
    ui_print " "
    ui_print " - Всё готово! С любовью, NLSound Team. -"
    ui_print " "
  fi
fi
#!/system/bin/sh

# restart
if [ "$API" -ge 24 ]; then
  killall audioserver
else
  killall mediaserver
fi

#!/system/bin/sh
MODDIR=${0%/*}
INFO=/data/adb/modules/.NLSound-files
MODID=NLSound
LIBDIR=/system/vendor
MODPATH=/data/adb/modules/NLSound

#AML FIX by reiryuki@GitHub
DIR=$AML/system/vendor/odm/etc
if [ -d $DIR ] && [ ! -f $AML/disable ]; then
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
fi


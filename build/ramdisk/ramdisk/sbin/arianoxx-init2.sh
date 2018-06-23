#!/system/bin/sh
# 
# Init ArianoxxKernel 2
#

ARIANO_DIR="/data/.arianoxxkernel"
LOG="$ARIANO_DIR/arianoxxkernel.log"

RESETPROP="/sbin/resetprop -v -n"


# Mount
$BB mount -t rootfs -o remount,rw rootfs;
$BB mount -o remount,rw /system;
$BB mount -o remount,rw /data;
$BB mount -o remount,rw /;

# Create arianoxxkernel folder
if [ ! -d $ARIANO_DIR ]; then
	mkdir -p $ARIANO_DIR;
fi


(
	# tweaks
	su -c "stop secure_storage"
        # mediakill (Credits: lyapota)
        killall -9 android.process.media
        killall -9 mediaserver

	# deepsleep fix
	for i in `ls /sys/class/scsi_disk/`; do
		cat /sys/class/scsi_disk/$i/write_protect 2>/dev/null | grep 1 >/dev/null
		if [ $? -eq 0 ]; then
			echo 'temporary none' > /sys/class/scsi_disk/$i/cache_type
		fi
	done
	
	
	# Google play services wakelock fix
	echo "## -- GooglePlay wakelock fix" >> $LOG
	su -c "pm enable com.google.android.gms/.update.SystemUpdateActivity"
	su -c "pm enable com.google.android.gms/.update.SystemUpdateService"
	su -c "pm enable com.google.android.gms/.update.SystemUpdateService$ActiveReceiver"
	su -c "pm enable com.google.android.gms/.update.SystemUpdateService$Receiver"
	su -c "pm enable com.google.android.gms/.update.SystemUpdateService$SecretCodeReceiver"
	echo " " >> $LOG

	# SafetyNet
	chmod 640 /sys/fs/selinux/enforce
	chmod 440 /sys/fs/selinux/policy
	

	# Init.d support
	echo "## -- Start Init.d support" >> $LOG
	if [ ! -d /system/etc/init.d ]; then
	    	mkdir -p /system/etc/init.d;
	fi

    	chown -R root.root /system/etc/init.d;
	chmod 777 /system/etc/init.d;

	if [ "$(ls -A /system/etc/init.d)" ]; then
		chmod 777 /system/etc/init.d/*;

		for FILE in /system/etc/init.d/*; do
			echo "## Executing init.d script: $FILE" >> $LOG
			sh $FILE >/dev/null;
	    	done;
	else
		echo "## No files found" >> $LOG
	fi
	echo "## -- End Init.d support" >> $LOG
	echo " " >> $LOG


	# Fix personalist.xml
	if [ ! -f /data/system/users/0/personalist.xml ]; then
		touch /data/system/users/0/personalist.xml
		chmod 600 /data/system/users/0/personalist.xml
		chown system:system /data/system/users/0/personalist.xml
	fi


	# Install APK
	echo "## -- Start Install APK" >> $LOG
	if [ ! -d $ARIANO_DIR/apk ]; then
		mkdir -p $ARIANO_DIR/apk;
		chown -R root.root $ARIANO_DIR/apk;
		chmod 750 $ARIANO_DIR/apk;
	fi

	if [ "$(ls -A /$ARIANO_DIR/apk)" ]; then
		cd $ARIANO_DIR/apk
		chmod 777 *;
		for apk in *.apk; do
			echo "## Install $apk" >> $LOG
			pm install -r $apk >/dev/null;
			rm $apk
		done;
	else
		echo "## No files found" >> $LOG
	fi
	echo "## -- End Install APK" >> $LOG


) 2>&1 | tee -a ./$LOG

chmod 777 $LOG

# Unmount
$BB mount -t rootfs -o remount,ro rootfs;
$BB mount -o remount,ro /system;
$BB mount -o remount,rw /data;
$BB mount -o remount,ro /;

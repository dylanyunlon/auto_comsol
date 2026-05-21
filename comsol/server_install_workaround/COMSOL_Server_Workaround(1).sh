#!/bin/sh

echo
echo  COMSOL Server Installer Work-around Script
echo           2016 TeAM SolidSQUAD-SSQ
echo

# assume working dir is COMSOL installation root

COMSOLROOT="$PWD"

# check architecture

[ "`uname`" == "Linux" ] && COMSOL_TARS="fl fl_setup_glnxa64 fl_setup_maclnx fl_jvm_glnxa64 fl_glnxa64 mph_maclnx mph_glnxa64"
[ "`uname`" == "Darwin" ] && COMSOL_TARS="fl fl_setup_maclnx fl_maclnx fl_jvm_maci64 fl_maci64 mph_maclnx mph_maci64"


# tell user he has to run the script from COMSOL Server folder

[ ! -e "$COMSOLROOT/comsolsetup.log" ] && echo -e "ERROR: This script should be executed\n  from the COMSOL Server installation directory\n  (where comsolsetup.log resides)" && exit 1

# check if we can write to folder

[ ! -w "$COMSOLROOT/comsolsetup.log" ] && echo -e "ERROR: Cannot write to folder \"$COMSOLROOT\".\n  If COMSOL Server was installed as root, run this script as root too\n otherwise run it as user which made the installation of COMSOL Server!" && exit 2

# let us extract the source location and check if it accessible

COMSOLDVD="`grep "^cs.installroot" "$COMSOLROOT/comsolsetup.log" | awk '{print $3}'`"

echo "COMSOL SERVER Installation Path = $COMSOLROOT"
echo "COMSOL Server Installation Source Path = $COMSOLDVD"

# check if source is accessible

[ ! -r "$COMSOLDVD/setupconfig.ini" ] && echo "The installaton source \"$COMSOLDVD\" id not accessible! Make sure the DVD is mounted" && exit 3

# now start untaring FL archives

for COMSOL_TAR in $COMSOL_TARS
do
  tar -xf "$COMSOLDVD/archives/$COMSOL_TAR.isa" -C "$COMSOLROOT"
done

# Null the bin\tomcat\conf\login.properties

echo > "$COMSOLROOT/bin/tomcat/conf/login.properties"

# Mission complete

echo
echo All done! Enjoy!
echo

exit 0
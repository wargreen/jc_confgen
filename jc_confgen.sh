#!/bin/bash

# SF = Sampling Frequency, in Hz [44100, 96000]
# IS = Impulse Start sample
# ERS = Erly Reflection Start sample
# LRS = Late Reflection Start sample
# jname = Jack name
# fname = impulse file name
#
# USAGE : CD in your Impulse folder and run $jc_confgen.sh IS ERS LRS jname fname
# and adjust gains...
# ex, for maeshawe, form non-daw ambi package : jc_confgen.sh 146 664 1376 maeshawe MH3_000_WXYZ_48k.amb
#
# Depend of : SOX

IS=$1
ERS=$2
LRS=$3
jname=$4
fname=$5


SF=$(sox --i -r $fname)


# resample [freq dest] [value]
function resample
{
#	resmpl=$(echo "scale=4;$1/$SF*$2" | bc)
#	echo "scale=0;$resmpl" | bc
	awk  'BEGIN { rounded = sprintf("%.0f", '$1'/'$SF'*'$2'); print rounded }'
}

#apply [freq_dest]
function apply
{

	echo "Compute for $1..."
	calcule $1
	echo -e "$HEADER \n$JACKIO \n$RESPONSES" > $fnewname.conf
	if [[ $SF != $1 ]]
		then sox $fname "$fnewname"."${fname##*.}" rate -v -L $1
		else
			clean=$fnewname
	fi
}



#calcule [freq dest]
# array [0] = early delay; [1] = early offset; [2] early lenght; [3] late delay; [4] late offset
function calcule
{
	resample_IS=$(resample $1 $IS)
	resample_ERS=$(resample $1 $ERS)
	resample_LRS=$(resample $1 $LRS)
	val[1]=$resample_ERS
	val[0]=$(($resample_ERS-$resample_IS))
	val[2]=$(($resample_LRS-$resample_ERS))
	val[4]=$resample_LRS
	val[3]=$(($resample_LRS-$resample_IS))
	fnewname="${fname%.*}"_$(echo $1 | sed -e 's/\([0-9][0-9]\).*/\1/')
	
	RESPONSES="/impulse/read  1   1   0.5   "${val[3]}"   "${val[4]}"   0   1   $fnewname."${fname##*.}"
/impulse/read  1   2   0.5   "${val[3]}"   "${val[4]}"   0   2   $fnewname."${fname##*.}"
/impulse/read  1   3   0.5   "${val[3]}"   "${val[4]}"   0   3   $fnewname."${fname##*.}"
/impulse/read  1   4   0.5   "${val[3]}"   "${val[4]}"   0   4   $fnewname."${fname##*.}"

/impulse/read  2   1   0.5   "${val[0]}"   "${val[1]}"   "${val[2]}"   1   $fnewname."${fname##*.}"
/impulse/read  3   2   0.5   "${val[0]}"   "${val[1]}"   "${val[2]}"   2   $fnewname."${fname##*.}"
/impulse/read  4   3   0.5   "${val[0]}"   "${val[1]}"   "${val[2]}"   3   $fnewname."${fname##*.}"
/impulse/read  5   4   0.5   "${val[0]}"   "${val[1]}"   "${val[2]}"   4   $fnewname."${fname##*.}""
}



RESDIR=$(echo $PWD)
HEADER="/cd '$RESDIR'"
JACKIO="/convolver/new	5	4	512	500000
/input/name   1   $jname.In.Tail
/input/name   2   $jname.In.W
/input/name   3   $jname.In.X
/input/name   4   $jname.In.Y
/input/name   5   $jname.In.Z
#
/output/name  1   Out.W
/output/name  2   Out.X
/output/name  3   Out.Y
/output/name  4   Out.Z"



if [[ $# -lt 5 ]] || [[ "$1" = "--help" ]]
	then
	echo "Usage : \$cd to your impulse responce folder, and launch this script with :"
	echo "		IS = Impulse Start sample"
	echo "		ERS = Erly Reflection Start sample"
	echo "		LRS = Late Reflection Start sample"
	echo "		jname = Jack name"
	echo "		fname = impulse file name"
	echo ""
	echo "   \$jc_confgen.sh IS ERS LRS jname fname"
	echo ""
	echo " 		This script use SOX"
	exit 1
else

	apply 44100
	apply 48000
	apply 88200
	apply 96000


	echo "Clean..."
	mv $fname $clean."${fname##*.}"
	exit 0
fi

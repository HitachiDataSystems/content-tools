#!/bin/bash

#Required Input Parameters
TENANT=""
USER=""
PASSWD=""
CONTAINER_NUM=""
WORKERSPERNODE=""

#Optional Input Parameters with Defaults
TEMPLATE="10-Stage-template.xml"
NODES="4"
RUNTIME="3600"
INTERVAL="15"
OBJ_SIZE_KB="1"
WRITE="100"
READ="0"
DELETE="0"
SIGNER="v4"
INSECURE="false"
PROTOCOL="https"
OPTIMIZE_DIR="true"
SUBMIT_MODE="false"

#Local Variables:
TEMP_XML="temp.xml"
COMMAND="$0 $@"
WRAPPER_DIR=`dirname $0`
WORKLOAD_DIR="$WRAPPER_DIR/wrapper-workloads"
TEMP_XML="$WRAPPER_DIR/temp.xml"

Usage()
{
    echo
    echo "This script is a wrapper to run the HCP COSBench workload with the following parameters"
    echo "  -h     Display this help and exit"
    echo "  -ten   The hcp tenant domain                    REQUIRED"
    echo "  -u     Tenant user name:                        REQUIRED (unless -auth anon)"
    echo "  -p     Tenant user Password:                    REQUIRED (unless -auth anon)"
    echo "  -bkt   Bucket number (in bucket name)           REQUIRED"
    echo "  -wpn   Workers per node, per stage.             REQUIRED"
    echo "         e.g. For 10 workstages: -wpn 105,95,85,65,45,25,15,10,5,1"
    echo "  -auth  Auth type, one of: hcp, anon, v2 or v4   DEFAULT = v4"
    echo "  -os    Object size in KB                        DEFAULT = 1"
    echo "  -n     Number of HCP nodes:                     DEFAULT = 4"
    echo "  -rt    Workstage run time in seconds            DEFAULT = 3600"
    echo "  -ri    Metric reporting interval in seconds     DEFAULT = 15"
    echo "  -t     Path to a template workload              DEFAULT = template.xml" 
    echo "  -w     Percent write:                           DEFAULT 100"
    echo "  -r     Percent read:                            DEFAULT 0"
    echo "  -d     Percent delete:                          DEFAULT 0"
    echo "         w + r + d must equal 100"
    echo "  -insecure Disable SSL certificate validation"
    echo "  -http     Use http protocol instead of https"
    echo "  -nodir    Use no directory structure like standard S3 COSBench driver"
    echo "  -submit   Submit the workload, if omitted write the config to temp.xml and exit"
    echo "e.g. to test using all defaults"
    echo "./cos_wrapper.sh -ten ten1.hcp.coe.cse.com -u dev -p start123 -bkt 7 -wpn 105,95,85,65,45,25,15,10,5,1"
    echo "OR to submit with all arguments specified"
    echo "./cos_wrapper.sh -submit -t ./template.xml -ten ten1.hcp.coe.cse.com -u dev -p start123 -n 4 -rt 3600 -ri 15 -bkt 7 -os 100000 -w 60 -r 30 -d 10 -wpn 105,95,85,65,45,25,15,10,5,1 -auth hcp -insecure -http -nodir"
}

GenerateWorkload()
{
		WARMUPWKR=$((100*$NODES))
    sed -e "s|@nodes|$NODES|g;
        s|@tenant|$TENANT|g;
        s|@user|$USER|g;
        s|@passwd|$PASSWD|g; 
        s|@containernum|$CONTAINER_NUM|g; 
        s|@objsizekb|$OBJ_SIZE_KB|g; 
        s|@write|$WRITE|g; 
        s|@read|$READ|g; 
        s|@delete|$DELETE|g;
        s|@signer|$SIGNER|g;
        s|@runtime|$RUNTIME|g;
        s|@interval|$INTERVAL|g;
        s|@insecure|$INSECURE|g;
        s|@protocol|$PROTOCOL|g;
        s|@diroptimize|$OPTIMIZE_DIR|g;
        s|@workerswm|$WARMUPWKR|g;
        s|@launchcommand|$COMMAND|g" $TEMPLATE > $TEMP_XML

    arr1=(`echo $WORKERSPERNODE | sed 's/,/\n/g'`)

    count=1
    for i in "${arr1[@]}"; do
        arr2[$count]=`expr $i \* $NODES`
        count=`expr $count + 1` 
    done

    for worker in $(seq 1 `expr $count - 1`); do
        sed -i -e "s/@workers$worker/${arr2[worker]}/" $TEMP_XML
    done
    
    sed -i -e "s/@workersX/${arr2[`expr $count - 1`]}/g" $TEMP_XML
}

Submit()
{
   if [ -f $TEMP_XML ]; then
      echo "Submitting the COSBench workload"
      workloadnum=`/opt/cosbench/cos/cli.sh submit $TEMP_XML | awk '{print $4}'`
      Workload_XML="$WORKLOAD_DIR/$workloadnum-Workload.xml"
      mv $TEMP_XML $Workload_XML
      echo 
      echo "Workload is saved as $Workload_XML"
   fi
}

mkdir -p $WORKLOAD_DIR

#Split Command string on this string " -" and count the resulting tokens to determine the number of arguments
LOOP=$(( $(echo $COMMAND | awk -F " -" '{print NF}') - 1 ))

#
# Parse the command line argument
#
for arg in $(seq $LOOP); do
    if [ ${!arg} == "-h" ]; then 
        Usage
        exit
    elif [ ${!arg} == "-t" ]; then
        shift         
        TEMPLATE=${!arg}
    elif [ ${!arg} == "-ten" ]; then
        shift
        TENANT=${!arg}
    elif [ ${!arg} == "-u" ]; then
        shift
        USER=${!arg}
    elif [ ${!arg} == "-p" ]; then
        shift
        PASSWD=${!arg}
    elif [ ${!arg} == "-n" ]; then
        shift
        NODES=${!arg}
    elif [ ${!arg} == "-bkt" ]; then 
        shift
        CONTAINER_NUM=${!arg}
    elif [ ${!arg} == "-os" ]; then
        shift
        OBJ_SIZE_KB=${!arg}
    elif [ ${!arg} == "-w" ]; then
        shift
        WRITE=${!arg}
    elif [ ${!arg} == "-r" ]; then  
        shift
        READ=${!arg}
    elif [ ${!arg} == "-d" ]; then
        shift
        DELETE=${!arg}
    elif [ ${!arg} == "-wpn" ]; then
        shift
        WORKERSPERNODE=${!arg}
    elif [ ${!arg} == "-rt" ]; then
        shift
        RUNTIME=${!arg}
    elif [ ${!arg} == "-ri" ]; then
        shift
        INTERVAL=${!arg}
    elif [ ${!arg} == "-auth" ]; then
        shift
        SIGNER=${!arg}   
    elif [ ${!arg} == "-insecure" ]; then
        INSECURE="true"
    elif [ ${!arg} == "-http" ]; then
        PROTOCOL="http"
    elif [ ${!arg} == "-nodir" ]; then
        OPTIMIZE_DIR="false"
    elif [ ${!arg} == "-submit" ]; then
        SUBMIT_MODE="true" 
    fi    
done

INVALIDARGS="false"
if [ "$TENANT" == "" ]; then
		echo "-ten is a required parameter."
		INVALIDARGS="true"
fi
if [ "$SIGNER" != "anon" ] && [ "$USER" == "" ]; then
		echo "-u is a required parameter unless -auth=anon."
		INVALIDARGS="true"
fi
if [ "$SIGNER" != "anon" ] && [ "$PASSWD" == "" ]; then
		echo "-p is a required parameter unless -auth=anon."
		INVALIDARGS="true"
fi
if ! [[ $CONTAINER_NUM =~ ^[0-9]+$ ]]; then
    echo "-bkt is a required parameter and must be an integer."
		INVALIDARGS="true"
fi
if [ "$WORKERSPERNODE" == "" ]; then
		echo "-wpn is a required parameter."
		INVALIDARGS="true"
fi
if ! [ $((WRITE + READ + DELETE)) -eq 100 ]; then
    echo "'-w' + '-r' + '-d' must add up to 100."
		INVALIDARGS="true"
fi
if [ "$INVALIDARGS" == "true" ]; then
		echo "Run the command with -h to see help."
		exit
fi

GenerateWorkload

if ! [ $SUBMIT_MODE == "true" ]; then
		echo "Workload configuration saved as $TEMP_XML"
else
    Submit
    exit
fi

#!/bin/bash

TEMPLATE=""
NODES=""
CONTAINER_NUM=""
WORKERSPERNODE=""
OBJ_SIZE_KB=""
WRITE=""
READ=""
DELETE=""
USER=""
PASSWD=""
TENANT=""
TEMP_XML="temp.xml"
TOTAL_WORKERS=""
SIGNER=""
SECURE=""
PROTOCOL=""
OPTIMIZE_DIR=""
TEST_MODE="False"
SUBMIT_MODE="False"


usage()
{
    echo
    echo "This script is a wrapper to run the COSBench workload with the following parameters"
    echo "  -h   Display this help and exit"
    echo "  -t   This is a path to template workload xml" 
    echo "  -e   This is an endpoint in workload xml which is required to create the namespace"
    echo "  -u   User name to login to HCP tenant"
    echo "  -p   Password for user to login to HCP tenant"
    echo "  -n   Total number of nodes on HCP cluster"
    echo "  -cn  This is the container number in \"r(<cn>, <cn>)\" format like \"r(7,7)\""
    echo "  -os  This is the object size in KiloBytes"
    echo "  -wpn This is the worker per node number and it includes first worker as warmup"
    echo "       So considering the 10 workstages it takes 10 agruments separated by comma"
    echo "       e.g. -wpn 105,95,85,65,45,25,15,10,5,1"
    echo "  -w   This is the percentage of write operation"
    echo "  -r   This is the percentage of read operation"
    echo "  -d   This is the percentage of delete operation"
    echo "  -sn  This is type of authentication, it can be either hcp, anon, v2 or v4"
    echo "  -s   Whether or not to disable certificate verification for SSL, it cab be true or false"
    echo "  -pro Whether or not to use the SSL, it can http or https"
    echo "  -od  Whether or not to use an optimized directory structure, it can be true or false"
    echo "  -Test    This mode is to generate the workload configuration"
    echo "  -submit   Generate and submit the generated workload"
    echo "e.g."
    echo "./cos_wrapper.sh -t ./template.xml -e ten1.hcp.coe.cse.com -u dev -p start123 -n 4 -cn \"r(7,7)\" -os 100000 -w 60 -r 30 -d 10 -wpn 105,95,85,65,45,25,15,10,5,1 -sn hcp -s true -pro http -od true -test"
    echo "OR"
    echo "./cos_wrapper.sh -t ./template.xml -e ten1.hcp.coe.cse.com -u dev -p start123 -n 4 -cn \"r(7,7)\" -os 100000 -w 60 -r 30 -d 10 -wpn 105,95,85,65,45,25,15,10,5,1 -sn hcp -s true -pro http -od true -submit"
}

test_mode()
{
    sed -e "s/@nodes/$NODES/g;
        s/@tenant/$TENANT/g;
        s/@user/$USER/g;
        s/@passwd/$PASSWD/g; 
        s/@containernum/$CONTAINER_NUM/g; 
        s/@objsizekb/$OBJ_SIZE_KB/g; 
        s/@write/$WRITE/g; 
        s/@read/$READ/g; 
        s/@delete/$DELETE/g;
        s/@signer/$SIGNER/g;
        s/@insecure/$SECURE/g;
        s/@protocol/$PROTOCOL/g;
        s/@diroptimize/$OPTIMIZE_DIR/g;
        s/@workerswm/400/g" $TEMPLATE > $TEMP_XML

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
    sed -i -e "s|@launchcommand|$cmd|" $TEMP_XML
}

Submit()
{
   if [ -f $TEMP_XML ]; then
      echo "Submitting the COSBench workload"
      workloadnum=`/opt/cosbench/cos/cli.sh submit $TEMP_XML | awk '{print $4}'`
      Workload_XML="$workloadnum-Workload.xml"
      mv $TEMP_XML $Workload_XML
      echo 
      echo "Workload is saved as $Workload_XML"
   fi
}


#LOOP=$(($# / 2))
LOOP=`expr $# / 2`
if [ $LOOP == 0 ] && [ $# != 0 ]; then
#    LOOP=$(($LOOP + 1))
    LOOP=`expr $LOOP + 1`
fi

if [ $# != 31 ]; then
    if [ $# == 0 ] || [ $1 != "-h" ]; then
        echo "There are missing parameters, please see the help."
        exit
    fi
else
    LOOP=`expr $LOOP + 1`
fi


cmd="$0 $@"
cmd=`echo $cmd | awk '{$32=""; print}'`

#
# Parse the command line argument
#
for arg in $(seq $LOOP); do
    if [ ${!arg} == "-h" ]; then 
        usage
        exit
    elif [ ${!arg} == "-t" ]; then
        shift         
        TEMPLATE=${!arg}
    elif [ ${!arg} == "-e" ]; then
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
    elif [ ${!arg} == "-cn" ]; then 
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
    elif [ ${!arg} == "-sn" ]; then
        shift
        SINGER=${!arg}   
    elif [ ${!arg} == "-s" ]; then
        shift
        SECURE=${!arg}
    elif [ ${!arg} == "-pro" ]; then
        shift
        PROTOCOL=${!arg}
    elif [ ${!arg} == "-od" ]; then
        shift
        OPTIMIZE_DIR=${!arg}
    elif [ ${!arg} == "-test" ]; then
        TEST_MODE="True"   
    elif [ ${!arg} == "-submit" ]; then
        SUBMIT_MODE="True" 
    fi    
done

if [ $TEST_MODE == "True" ]; then
    echo "Generating the workload configuration and saving it in temp.xml."
    test_mode
    exit
fi

if [ $SUBMIT_MODE == "True" ]; then
    test_mode
    Submit
    exit
fi

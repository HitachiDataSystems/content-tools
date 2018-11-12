# COSBench Wrapper
**A Performance Test Utility for Hitachi Content Platform**

The Content Solutions Engineering (CSE) team recently released a new COSBench driver for HCP Storage. You can read all about it and learn how to install and use it in Tim Palace's blog post, [HCP Storage Adaptor for COSBench](https://community.hitachivantara.com/community/developer-network/content-solutions-engineering/blog/2018/10/18/hcp-storage-adaptor-for-cosbench). 

Creating COSBench workload configuration files is a tedious task, time consuming and error prone. If you want to rerun previous tests you have to keep a large collection of configuration files and do a lot of copy/paste or find/replace for different systems or to tweak parameters. At some point it just becomes unwieldy. That is why the CSE team has created a utility that we call the "COSBench Wrapper" as an homage to the "rise wrapper" and the "'rise wrapper' wrapper" which may be familiar to readers with an HCP Engineering background. This utility is comprised of COSBench workload configuration template files, and a command line script called cos_wrapper.sh which allows the user to very quickly queue up any number of workloads with a series of short CLI commands.

# cos_wrapper.sh
## Description
The cos_wrapper.sh generates a COSBench workload configuration file for HCP. It submits the workload configuration to COSBench, and saves the configuration file with the COSBench workload ID into the wrapper-workloads folder.
 ## Installation
Download all of the files from this folder and save them to a folder called cosbench-wrapper in the COSBench home directory. The COSBench home directory is the directory that contains the COSBench files such as cosbench-start.sh and cosbench-stop.sh.
## Usage
```sh
# ./cos_wrapper.sh <required-arguments> [<optional-arguments>] [<flags>]
```
### Required Arguments
| Option | Description |
| ------ | ------ |
|-ten|The hcp tenant domain|
|-u|Tenant user name, not encoded|
|-p|Tenant user Password, not encoded|
|-bkt|Bucket number, will be appended to the bucket name|
|-wpn|Workers per node, per stage. e.g. For 10 workstages: |-wpn 105,95,85,65,45,25,15,10,5,1 |

### Optional Arguments
|Option|Description|Default|
| ------ | ------ | ------ |
|-auth|Auth type, one of: hcp, anon, v2 or v4|v4|
|-os|Object size in KB|1|
|-n|Number of HCP nodes:|4|
|-rt|Workstage run time in seconds|3600|
|-ri|Metric reporting interval in seconds for COSBench logs|15|
|-t|Path to a COSBench workload template configuration|10|-Stage|-template.xml|
|-w|Percent write:|100|
|-r|Percent read:|0|
|-d|Percent delete:|0|
* *w + r + d must equal 100*

### Optional Flags
|Option|Description|
| ------ | ------ |
|-h|Display help and exit|
|-insecure|Disable SSL certificate validation, almost always needed unless |-http is used or HCP certificates are trusted|
|-http|Use http protocol instead of https|
|-nodir|Use no directory structure like standard S3 COSBench driver|
|-no100|Disable expect 100 continue|
|-submit|Submit the workload to COSBench, if omitted write the config to temp.xml and exit

## Examples
Using all the defaults will generate a 4 node, 100 MB write only, 10 Hr.,10 stage workload config:
```sh 
# ./cos_wrapper.sh -ten ten1.hcp.test.com -u user -p pword -bkt 1 \
-wpn 275,250,225,200,175,150,125,100,75,50
```
Same as above but submitting the workload to COSBench, insecure for HCP self signed cert:

```.sh
./cos_wrapper.sh -ten ten1.hcp.test.com -u user -p pword -bkt 1 \
-wpn 275,250,225,200,175,150,125,100,75,50 -submit -insecure
```

Most tests on a freshly installed system will start with a warmup, use the 1 stage template for this and only one argument in the -wpn list. In this case I am running 100 worker threads per HCP node, 94% write, 5% read, and 1% delete:
```.sh
./cos_wrapper.sh -ten ten1.hcp.test.com -u user -p pword -bkt 2 -wpn 100 \
-w 94 -r 5 -d 1 -submit -t 1-Stage-template.xml -insecure
```

Mixed read, write and delete, with anonymous authentication:
```.sh
./cos_wrapper.sh -ten ten1.hcp.test.com -auth anon -bkt 2 \
-wpn 275,250,225,200,175,150,125,100,75,50 -w 60 -r 30 -d 10 -submit
```

100MB object write test, fewer threads per node :
```.sh
# ./cos_wrapper.sh -ten ten1.hcp.test.com -u user -p pword -bkt 3 \
-wpn 105,95,85,65,45,25,15,10,5,1 -os 100000 -submit
```

100MB object read test, must use same bucket as write test! Reads are much faster than writes, so only run each stage for 20 minutes (writes ran for an hour each) :
```.sh
./cos_wrapper.sh -ten ten1.hcp.test.com -u user -p pword -bkt 3 \
-wpn 105,95,85,65,45,25,15,10,5,1 -os 100000 -submit -r 100 -rt 1200
```

If you want to run a shorter test you can use the 3 stage template and specify a shorter stage runtime (rt) and reporting interval (ri). This test runs 3 stages for 20 seconds each at 275, 150, and 50 workers per node respectively. It will report metrics to the COSBench logs at 1 second intervals. It also uses native HCP authentication (not AWS auth), it will not use TLS/SSL, and it will not wait for "100-continue" before sending the data to the HCP :
```.sh
./cos_wrapper.sh -ten ten1.hcp.test.com -u user -p pword -bkt 4 \
-wpn 275,150,50 -t 3-Stage-template.xml -ri 1 -rt 20 -http -auth hcp \
-submit -no100
```

# Monitoring and Results
Monitor your tests and view summary results in the cosbench controller UI at http://127.0.0.1:19088/controller/index.html where the IP is your controller's IP.

Detailed results can be found in the cosbench archive folder. This folder contains subfolders named for the workload they represent. In each workloads subfolder you will find several csv files describing the results of the test. The reporting interval in these logs is determined by the -ri argument to cos_wrapper.sh.


# juicer
PBS version of https://github.com/aidenlab/juicer for Flashlite HPC.

# Simple Intructions
To replicate the workflow from [https://github.com/aidenlab/juicer/wiki/Running-Juicer-on-a-cluster](https://github.com/aidenlab/juicer/wiki/Running-Juicer-on-a-cluster) follow these steps:

```
#Change to a directory you want to install and run your juicer analyses, e.g.
cd /30days/natbutter

#Clone this repo to that folder
git clone https://github.com/natbutter/juicer.git

#Change into the repo directory
cd juicer

#Link the PBS scripts for ease (as is done on the official repo)
ln -s PBS/scripts scripts

#Make and get references and restriction_site files (put your own here as needed)
mkdir references; cd references
wget https://s3.amazonaws.com/juicerawsmirror/opt/juicer/references/Homo_sapiens_assembly19.fasta
wget https://s3.amazonaws.com/juicerawsmirror/opt/juicer/references/Homo_sapiens_assembly19.fasta.amb
wget https://s3.amazonaws.com/juicerawsmirror/opt/juicer/references/Homo_sapiens_assembly19.fasta.ann
wget https://s3.amazonaws.com/juicerawsmirror/opt/juicer/references/Homo_sapiens_assembly19.fasta.bwt
wget https://s3.amazonaws.com/juicerawsmirror/opt/juicer/references/Homo_sapiens_assembly19.fasta.pac
wget https://s3.amazonaws.com/juicerawsmirror/opt/juicer/references/Homo_sapiens_assembly19.fasta.sa
mkdir ../restriction_sites; cd ../restriction_sites
wget https://s3.amazonaws.com/juicerawsmirror/opt/juicer/restriction_sites/hg19_MboI.txt

#Get the juicer tools file to run with your version (if you need a different one to the repo)
cd ../scripts
wget https://hicfiles.tc4ga.com/public/juicer/juicer_tools.1.9.9_jcuda.0.8.jar
ln -s juicer_tools.1.9.9_jcuda.0.8.jar juicer_tools.jar

#Make a directory where you will be running your analysis (and populating with output files)
mkdir ../HIC003; cd ../HIC003
mkdir fastq; cd fastq
wget http://juicerawsmirror.s3.amazonaws.com/opt/juicer/work/HIC003/fastq/HIC003_S2_L001_R1_001.fastq.gz
wget http://juicerawsmirror.s3.amazonaws.com/opt/juicer/work/HIC003/fastq/HIC003_S2_L001_R2_001.fastq.gz

```
Now edit the ```scripts/juicer.sh``` script to point to the correct project, and adjust other configuration options. ***Note***, you may need to adjust some of the hardcoded ram/cpu resource requests throughout the workflow in addition to those fixed in the config header lines.

```
juiceDir="/30days/natbutter/juicer"
project='NCMAS-xx99'
```

Finally, run the script which will launch all the jobs and submit them to the queue:
```
cd /30days/natbutter/juicer/HIC003
../scripts/juicer.sh
```

### Directory structure
This is what my directory structrue looked like after setting everything up and running (to two levels deep):
```
natbutter@flashlite1:/30days/natbutter/juicer> tree -L 2
.
|-- HIC003
|   |-- aligned
|   |-- fastq
|   |-- logs
|   `-- splits
|-- PBS
|   `-- scripts
|-- README.md
|-- references
|   |-- Homo_sapiens_assembly19.fasta
|   |-- Homo_sapiens_assembly19.fasta.amb
|   |-- Homo_sapiens_assembly19.fasta.ann
|   |-- Homo_sapiens_assembly19.fasta.bwt
|   |-- Homo_sapiens_assembly19.fasta.pac
|   `-- Homo_sapiens_assembly19.fasta.sa
|-- restriction_sites
|   `-- hg19_MboI.txt
`-- scripts -> PBS/scripts

```

# Significant changes and updates to get running on the Flashlite HPC

[https://rcc.uq.edu.au/flashlite](https://rcc.uq.edu.au/flashlite)

Changes:
* Added ```$project``` variable and spceifed in every *qsub* with ```#PBS -A $project```
* ```nodes=1:ppn:1``` -> ```select=1:ncpus=1```
* Changed greps of "qstat" to cut at the correct place for Flashlite PBS
* Hardcoded a few ```mem=``` and ```ncpus=``` that may need to adjusted for specific runs
* Using local versions ```module load bwa/0.7.13``` and ```module load Java/1.8.0_45```
* No GPUs on Flashlite, so the HiCCUPs step is not tested.



# Original README for the PBS verison below
---------


Very new to coding and this is my first "big" project in modifying a script. So welcome to make it better!

This PBS version is modified mainly based on the LSF version, but also took other versions as reference. Main changed to create this version is build the job dependencies to guarantee the sequential steps of each job in the original juicer.sh script. #PBS -W depend=afterok:jobID headerline is used.
The launch stats steps and post processing steps are moved into two separate scripts to avoid the variable value problems (expansion) in multiple level of heredocs. These two scripts will be called from the main juicer.sh at the appropriate step.
As a summary, the follwing scripts have been modified:
juicer.sh
split_rmdups.awk
mega.sh
The following two scripts has been added (extracted from the juicer.sh)
launch_stats.sh
postprocessing.sh

All steps has been tested till the ARROWHEAD step.
*HiCCUP step has not been tested in this version because of some un-resolved error in loading Jcuda native libraries.

One important notice for successful run of this PBS version:
***The $groupname variable has to be maximally 7 characters long*****
This length may change according to your cluster setup. See below for the reason.
The jobs' dependency of this PBS version juicer is based on jobID of each step. And the jobID of each job is obtained through the qstat output based on the specific job Name, jobID_stepx= $(qstat |grep <specific job name string> |cut -c 1-7).  Unfortunately, PBS can not use job Name in building job dependency. The job Name column in qstat output has a maximum length of 16 characters by default. When the job Name exceeds this max length, the beginning part of the job Name string will be replaced by “…” and then followed by the last 13 characters (see examples below). If the job name is not fully displayed, the jobID value may be null due to the failure at grep step.  Each job Name contains the $groupname, which gives each run specific timestamp and avoid's disruption from other runs of juicer from the same user. A potential cause of this problem is the ${groupname} value being too long. I have added comments in the juicer.sh script for setting this variable. 
Below is a example of job names being too long:
$qstat
Job ID                    Name             User            Time Use S Queue
------------------------- ---------------- --------------- -------- - -----
2294690.pbs                STDIN            mzhibo          00:00:15 R batch          
2294778.pbs                make4Cbedgraph   mzhibo                 0 R batch          
2294784.pbs                ...dgraph1111111 mzhibo                 0 Q batch          
$

Zhibo

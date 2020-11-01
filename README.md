# juicer
PBS version of https://github.com/aidenlab/juicer for Flashlite HPC. Details of changes are in the [juicer/PBS/] directory.

# Simple Intructions
To replicate the workflow from [https://github.com/aidenlab/juicer/wiki/Running-Juicer-on-a-cluster](https://github.com/aidenlab/juicer/wiki/Running-Juicer-on-a-cluster) 

```
cd /30days/nathanielpeterbutterworth

git clone https://github.com/natbutter/juicer.git

cd juicer

ln -s scripts PBS 

mkdir refs 
cd refs

wget http://juicerawsmirror.s3.amazonaws.com/opt/juicer/work/HIC003/fastq/HIC003_S2_L001_R1_001.fastq.gz
wget http://juicerawsmirror.s3.amazonaws.com/opt/juicer/work/HIC003/fastq/HIC003_S2_L001_R2_001.fastq.gz

```
Now edit the ```juicer.sh``` script to point to the correct project etc. Note, you may need to adjust some of the hardcoded ram/cpu resource requests throughout the workflow in addition to those fixed in the config header lines.

```
project=XXXX
```

Finally, run the script which will launch all the jobs and submit them to the queue:
```
../scripts/juicer.sh
```

#!/bin/bash
jID_launch=$( qstat | grep Lnch_${groupname} | cut -d '.' -f 1 )
if [ -z $postproc ]
then
    waitstring3="#PBS -W depend=afterok:${jID_launch}"
fi
echo "waitstring3 is: ${waitstring3}"
echo $project
timestamp=$(date +"%s" | cut -c 4-10)
echo "running postprocwrap"
qsub <<- POSTPROCWRAP
#PBS -S /bin/bash
#PBS -q $queue
#PBS -A $project
#PBS -l $walltime
#PBS -l select=1:ncpus=1:mem=4g
#PBS -o ${logdir}/${timestamp}_postproc_wrap_${groupname}.log
#PBS -j oe
#PBS -N PPrWrp${groupname}
${waitstring3}

date +"%Y-%m-%d %H:%M:%S"

jID_hic30=\$(qstat | grep hic30_${groupname} |cut -d '.' -f 1)
echo \$jID_hic30
echo "try this..."
echo \$(qstat | grep hic30_${groupname} )
echo "--------"

if [ -z $postproc ]
then
    waitstring4="#PBS -W depend=afterok:\${jID_hic30}" 
fi
echo "waitstring4 is : \${waitstring4}"

timestamp=\$(date +"%s" | cut -c 4-10)
echo "running postprocess"
qsub <<POSTPROCESS
    #PBS -S /bin/bash
    #PBS -q $queue
    #PBS -l $long_walltime
    #PBS -l select=1:ncpus=1:mem=60g
    #PBS -o ${logdir}/\${timestamp}_postproc_${groupname}.log
    #PBS -j oe
    #PBS -N PProc_${groupname}
    #PBS -A $project
    \$waitstring4
	#This formerly had an ngpus=1
    date +"%Y-%m-%d %H:%M:%S"
    $load_java
    $load_cuda
    module list 
    export _JAVA_OPTIONS=-Xmx16384m
    export LC_ALL=en_US.UTF-8

    ${juiceDir}/scripts/juicer_postprocessing.sh -j ${juiceDir}/scripts/juicer_tools -i ${outputdir}/inter_30.hic -m ${juiceDir}/references/motif -g $genomeID
echo "done postprocess"
POSTPROCESS
echo "done postprocwrap"
POSTPROCWRAP

jID_postprocwrap=$( qstat |grep PPrWrp${groupname} | cut -d '.' -f 1 )
echo $jID_postprowrap
wait
timestamp=$(date +"%s" | cut -c 4-10)
echo "running finck"
qsub <<- FINCK
#PBS -S /bin/bash
#PBS -q $queue  
#PBS -l $walltime
#PBS -o ${logdir}/${timestamp}_prep_done_${groupname}.log
#PBS -j oe
#PBS -N Pdone_${groupname}
#PBS -W depend=afterok:${jID_postprocwrap}
#PBS -A $project
#PBS -l select=1:ncpus=1:mem=50gb

date +"%Y-%m-%d %H:%M:%S"    
jID_hic30=\$(qstat | grep hic30_${groupname} |cut -d '.' -f 1)
jID_stats0=\$(qstat | grep stats0${groupname} |cut -d '.' -f 1)
jID_stats30=\$(qstat | grep stats30${groupname} |cut -d '.' -f 1)
jID_hic=\$(qstat | grep hic0_${groupname} |cut -d '.' -f 1)
jID_postproc=\$(qstat | grep PProc_${groupname} |cut -d '.' -f 1)

waitstring5="#PBS -W depend=afterok:\${jID_postproc}"
if [ -z $postproc ]
then
    waitstring5="#PBS -W depend=afterok:\${jID_hic30}:\${jID_stats0}:\${jID_stats30}:\${jID_hic}:\${jID_postproc}"
fi
timestamp=\$(date +"%s" | cut -c 4-10)
echo "running done"
qsub <<DONE
    #PBS -S /bin/bash
    #PBS -q $queue
    #PBS -l $walltime
    #PBS -l select=1:ncpus=1:mem=4g
    #PBS -o ${logdir}/\${timestamp}_done_${groupname}.log
    #PBS -j oe
    #PBS -N done_${groupname}
    #PBS -A $project
    \${waitstring5}

    date +"%Y-%m-%d %H:%M:%S"    
    export splitdir=${splitdir}
    export outputdir=${outputdir}
    ${juiceDir}/scripts/check.sh
echo "done done"
DONE
echo "done finck"
FINCK


#!/bin/bash

###########################################################################################
# Script: 01.primeseq_QC.sh
# Purpose: Run quality control steps for Prime-seq FASTQ files (raw, merged, trimmed)
#
# Author: Paulo Jannig
# GitHub: https://github.com/paulojannig
###########################################################################################

# Load experiment-specific configuration
source config.sh

###########################################################################################
# How to run this script
#
# 1. Navigate to the analysis directory:
#       cd ~/github_resources/Prime-seq_analysis
#
# 2. (Optional) Start a screen session:
#       screen
#
# 3. Activate Pixi environment:
#       pixi install
#       pixi shell -e default --manifest-path pixi.toml
#
# 4. Run the script with logging:
#       nohup ./scripts/01.primeseq_QC.sh >> log.01.primeseq_QC.txt
#
###########################################################################################

# Script starts here
# Start logging ------------
echo " ========================================================================================== "
echo "Date: "`date`
echo "Experiment: ${EXPERIMENT}" - Prime-seq QC
echo "========================================================================================== "
printf "\n"

# Prep environment for Prime-seq analysis
## Create dependencies
mkdir -p ${PATH_EXPERIMENT}
cd ${PATH_EXPERIMENT}

mkdir -p \
    00.reports/ \
    01.metadata/ \
    miscellaneous \
    scripts \
    Data/00.reports/Untrimmed/FastQC_untrimmed_output \
    Data/00.reports/Trimmed/FastQC_trimmed_output \
    Data/01.RawData/multiple_lanes/${EXPERIMENT} \
    Data/01.RawData/merged/ \
    Data/02.TrimmedData

#cp ~/github_resources/Prime-seq_analysis/templates/primeseq_zUMIs.yaml ~/github_resources/Prime-seq_analysis/primeseq_zUMIs_${EXPERIMENT}.yaml
#cp ~/github_resources/Prime-seq_analysis/templates/Template_Primeseq_barcodes_samples.txt ~/github_resources/Prime-seq_analysis/Primeseq_barcodes_samples.txt

cp -r ~/github_resources/Prime-seq_analysis/scripts/*.Rmd ${PATH_EXPERIMENT}/scripts/
cp -r ~/github_resources/Prime-seq_analysis/scripts/*.R ${PATH_EXPERIMENT}/scripts/
#cp -r ~/github_resources/Prime-seq_analysis/templates/sampleInfo.xlsx ${PATH_EXPERIMENT}/01.metadata/
cp -r ~/github_resources/Prime-seq_analysis/miscellaneous/pathways_names_replacements.txt ${PATH_EXPERIMENT}/miscellaneous/

## Copy files
echo " ==================== Copying Fastq files and reports ==================== " `date`
if [ $PLATFORM = "MGI" ]
then
    echo " ==================== MGI data ==================== "
    cp ${PATH_RAW_DATA}/${FLOWCELL}/L0*/*${PRIMESEQ_INDEX}*.fq.gz ${PATH_EXPERIMENT}/Data/01.RawData/multiple_lanes/${FLOWCELL}_${PRIMESEQ_INDEX}
    cp ${PATH_RAW_DATA}/${FLOWCELL}/L0*/*${PRIMESEQ_INDEX}*.fq.fqStat.txt ${PATH_EXPERIMENT}/Data/00.reports/
    cp ${PATH_RAW_DATA}/${FLOWCELL}/L0*/*${PRIMESEQ_INDEX}*.report.html ${PATH_EXPERIMENT}/Data/00.reports/
    printf "\n"
elif [ $PLATFORM = "NOVOGENE" ]
then
    echo " ==================== Novogene data ==================== "
    cp ${PATH_RAW_DATA}/*.fq.gz ${PATH_EXPERIMENT}/Data/01.RawData/multiple_lanes/${EXPERIMENT}
    cp ${PATH_RAW_DATA2}/*.fq.gz ${PATH_EXPERIMENT}/Data/01.RawData/multiple_lanes/${EXPERIMENT}
    printf "\n"
else
  echo "Unsupported PLATFORM variable, check config.sh: $PLATFORM"
  exit 1
fi

# Merge multiple lanes
echo " ==================== Merging Fastq files from multiple lanes ==================== " `date`
python ~/github_resources/Prime-seq_analysis/scripts/merge_fqs.py -n 10 -i ${PATH_EXPERIMENT}/Data/01.RawData/multiple_lanes/ -o ${PATH_EXPERIMENT}/Data/01.RawData/merged/
printf "\n"


# QC Untrimmed fastq
MERGED_DIR="${PATH_EXPERIMENT}/Data/01.RawData/merged/${EXPERIMENT}"
if [[ -d "$MERGED_DIR" && "$(ls -A "$MERGED_DIR"/*.fq.gz 2>/dev/null)" ]]; then
    
    echo " ==================== Quality control of merged Fastq files ==================== " `date`
    fastqc ${MERGED_DIR}/*.fq.gz \
        -o ${PATH_EXPERIMENT}/Data/00.reports/Untrimmed/FastQC_untrimmed_output
    
    multiqc --force \
        ${PATH_EXPERIMENT}/Data/00.reports/Untrimmed/FastQC_untrimmed_output \
        --outdir ${PATH_EXPERIMENT}/Data/00.reports/Untrimmed/MultiQC_untrimmed_output

elif [[ -d "$MERGED_DIR" ]]; then
    echo "Merged directory exists but contains no FASTQ files"
    echo "Stopping analysis"
    exit 1
else
    echo "Error: merged FASTQ directory not found or merge failed"
    echo "Stopping analysis"
    exit 1
fi

# Trimming the Primeseq .fastq
echo " ==================== Trimming Fastq files ==================== " `date`
python ~/github_resources/Prime-seq_analysis/scripts/trim_r1A_r2i.py -n 10 -i ${PATH_EXPERIMENT}/Data/01.RawData/merged/${EXPERIMENT} -t ${PATH_EXPERIMENT}/Data/02.TrimmedData/

# QC Trimmed fastq
## Quality control of cutadapt trimmed .fastq
TRIMMED_DIR="${PATH_EXPERIMENT}/Data/02.TrimmedData"
if [[ -d "$TRIMMED_DIR" && "$(ls -A "$TRIMMED_DIR"/*fastq.gz 2>/dev/null)" ]]; then

    echo " ==================== Quality control of cutadapt trimmed Fastq files ==================== " `date`

    fastqc ${TRIMMED_DIR}/*fastq.gz \
        -o ${PATH_EXPERIMENT}/Data/00.reports/Trimmed/FastQC_trimmed_output

    multiqc --force \
        ${PATH_EXPERIMENT}/Data/00.reports/Trimmed/FastQC_trimmed_output \
        --outdir ${PATH_EXPERIMENT}/Data/00.reports/Trimmed/MultiQC_trimmed_output

elif [[ -d "$TRIMMED_DIR" ]]; then
    echo "Trimmed directory exists but contains no FASTQ files"
    echo "Stopping analysis"
    exit 1
else
    echo "Error: trimmed FASTQ directory not found or empty"
    echo "Stopping analysis"
    exit 1
fi

echo " ==================== Organizing files ==================== " `date`
# backup config.sh file
cp ~/github_resources/Prime-seq_analysis/config.sh ${PATH_EXPERIMENT}/scripts/
rm -r ${PATH_EXPERIMENT}/cat/

echo " ========================================================================================== "
printf "\n"
echo "Done!" `date`
# move log
mv ~/github_resources/Prime-seq_analysis/log.01.primeseq_QC.txt ${PATH_EXPERIMENT}/00.reports/
#!/bin/bash

###########################################################################################
# Script: 02.primeseq_zUMIs.sh
# Purpose: Run zUMIs on Prime-seq processed FASTQ files
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
#       nohup ./scripts/02.primeseq_zUMIs.sh >> log.02.primeseq_zUMIs.txt
#
###########################################################################################

# Script starts here
#
# Start logging ------------
echo " ========================================================================================== "
echo "Date: "`date`
echo "Experiment: ${EXPERIMENT}" - Prime-seq zUMIs
echo "========================================================================================== "
printf "\n"

# Prep environment for Prime-seq analysis
## Create dependencies
mkdir -p ${PATH_EXPERIMENT}
cd ${PATH_EXPERIMENT}

mkdir -p \
    00.reports/zUMIs/ \
    02.results/zUMIs/ \
    Data/03.zUMI_mapping

# zUMIs mapping
~/github_resources/zUMIs/zUMIs.sh -c -y ~/github_resources/Prime-seq_analysis/primeseq_zUMIs.yaml

echo " ==================== Organizing files ==================== " `date`
# Copy main zUMIs reports and results
cp -r ${PATH_EXPERIMENT}/Data/03.zUMI_mapping/zUMIs_output/stats/* ${PATH_EXPERIMENT}/00.reports/zUMIs/
cp -r ${PATH_EXPERIMENT}/Data/03.zUMI_mapping/zUMIs_output/*kept_barcodes_binned.txt ${PATH_EXPERIMENT}/00.reports/zUMIs/
cp -r ${PATH_EXPERIMENT}/Data/03.zUMI_mapping/zUMIs_output/expression/*.dgecounts.rds ${PATH_EXPERIMENT}/02.results/zUMIs/
cp -r ${PATH_EXPERIMENT}/Data/03.zUMI_mapping/zUMIs_output/expression/*.gene_names.txt ${PATH_EXPERIMENT}/02.results/zUMIs/

# Copy barcode file
cp ~/github_resources/Prime-seq_analysis/Primeseq_barcodes_samples.txt ${PATH_EXPERIMENT}/01.metadata

# move yaml file
cp ~/github_resources/Prime-seq_analysis/primeseq_zUMIs.yaml ${PATH_EXPERIMENT}/scripts/
mv ~/github_resources/Prime-seq_analysis/primeseq_zUMIs.run.yaml ${PATH_EXPERIMENT}/scripts/
rm -r ${PATH_EXPERIMENT}/cat/

echo " ========================================================================================== "
printf "\n"
echo "Done!" `date`
# move log
mv ~/github_resources/Prime-seq_analysis/log.02.primeseq_zUMIs.txt ${PATH_EXPERIMENT}/00.reports/
############################################################
# Experiment metadata
############################################################

# Name of the experiment (used to build folder paths)
EXPERIMENT=PJ101_TEMPLATE
#EXPERIMENT=PJ101_TEMPLATE

# Base directory where all output for this experiment will be stored
PATH_EXPERIMENT=/mnt/run/USER/${EXPERIMENT}

# Location of the run folder (MGI; e.g. /path/to/V350293965) or raw FASTQ files (Novogene)
PATH_RAW_DATA=/mnt/storage/USER/PJ101_TEMPLATE/a221123_AZ_Plac
#PATH_RAW_DATA=/mnt/storage/USER/PJ101_TEMPLATE/data_1
## Secondary raw data directory (optional)
### Use this ONLY if pooling FASTQ files from multiple Novogene sequencing runs
#PATH_RAW_DATA2=/mnt/storage/USER/PJ101_TEMPLATE/data_2

############################################################
# Sequencing platform
############################################################
# Platform that generated the data. Valid options:
#   NOVOGENE  → Illumina FASTQ structure from Novogene
#   MGI       → DNBSEQ/G400 data structure
PLATFORM=NOVOGENE

############################################################
# Additional settings required only if PLATFORM=MGI
############################################################

# Flowcell ID of the run (e.g. V350293965)
FLOWCELL=V350293965

# Prime-seq library index sequence used for demultiplexing
# (IDT i5 - Nextera i7 barcode ID)
PRIMESEQ_INDEX=IDTi51i7N701
#PRIMESEQ_INDEX=IDTi52i7N702
#PRIMESEQ_INDEX=IDTi53i7N703
#PRIMESEQ_INDEX=IDTi54i7N704
#PRIMESEQ_INDEX=IDTi55i7N705


#!/usr/bin/env python3
import gzip
import os
from collections import defaultdict

# Barcode-to-sample mapping
barcode_to_sample = {
    "TCCATACGCGAA": "M3-1",
    "CCTAACCTACAA": "M4-3",
    "ACGTATTGTCCA": "M3-2",
    "CAGCGGAACTTA": "M5-1",
    "GATTCATTCGGA": "M4-2",
    "TGTTATGGCCAA": "M2-1",
    "CCACGTAAGAGG": "M6-3",
    "AGCATAGCCACA": "M1-1",
    "CTTCCAGAGGCA": "M6-1",
    "TAGCGGTCTGCA": "M7-1",
    "TCGGTTCGCTCA": "M7-2"
}

files = [
    "AZ_Aorta_Library_MKDL240001393-1A_222TC7LT4_L3_1.fq.gz",
    "AZ_Aorta_Library_MKDL240001393-1A_222TC7LT4_L3_2.fq.gz",
    "AZ_Aorta_Library_MKDL240001393-1A_222TJNLT4_L3_1.fq.gz",
    "AZ_Aorta_Library_MKDL240001393-1A_222TJNLT4_L3_2.fq.gz",
    "AZ_Aorta_Library_MKDL240001393-1A_22K2MLLT3_L4_1.fq.gz",
    "AZ_Aorta_Library_MKDL240001393-1A_22K2MLLT3_L4_2.fq.gz",
]

# Pair files by _1/_2
pairs = defaultdict(dict)
for f in files:
    if f.endswith("_1.fq.gz"):
        key = f.replace("_1.fq.gz", "")
        pairs[key]["R1"] = f
    elif f.endswith("_2.fq.gz"):
        key = f.replace("_2.fq.gz", "")
        pairs[key]["R2"] = f

# Demultiplex each pair
for sample_key, frags in pairs.items():
    with gzip.open(frags["R1"], "rt") as r1, gzip.open(frags["R2"], "rt") as r2:
        # Open output files for whitelist barcodes
        out_files = {}
        for bc, sample_name in barcode_to_sample.items():
            out1 = gzip.open(f"{sample_name}_1.fq.gz", "at")
            out2 = gzip.open(f"{sample_name}_2.fq.gz", "at")
            out_files[bc] = (out1, out2)

        while True:
            r1_block = [r1.readline() for _ in range(4)]
            if not r1_block[0]:
                break
            r2_block = [r2.readline() for _ in range(4)]

            bc = r1_block[1][:12]  # first 12 nt barcode
            if bc in out_files:
                w1, w2 = out_files[bc]
                # Trim barcode from R1 sequence and quality
                s1_trimmed = r1_block[1][12:].strip()
                q1_trimmed = r1_block[3][12:].strip()

                # Write R1
                w1.write(r1_block[0])
                w1.write(s1_trimmed + "\n")
                w1.write(r1_block[2])
                w1.write(q1_trimmed + "\n")

                # Write R2 (unchanged)
                w2.writelines(r2_block)

        # Close output files
        for w1, w2 in out_files.values():
            w1.close()
            w2.close()

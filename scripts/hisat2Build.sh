#!/bin/bash -eufxv -o pipefail

mkdir -p hisat2

#gunzip files
echo "LOG: gunzipping fasta" &
gunzip ${fasta} &
echo "LOG: gunzipping gtf" &
gunzip ${gtf} &

#build the splice-site file
wait
echo "LOG: bulding the splice-site file" &
hisat2_extract_splice_sites.py genome.gtf > genome.ss &

#build the exon file
echo "LOG: building the exon file" &
hisat2_extract_exons.py genome.gtf > genome.exon &

#build the HISAT2 reference
wait
echo "LOG: building reference"
hisat2-build -p \$(nproc) --ss genome.ss --exon genome.exon genome.fa hisat2/genome
#!/usr/bin/env nextflow

//define input files
params.fasta_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/GRCh38.p13.genome.fa.gz"
params.fasta_name = "GRCh38.p13"
params.gtf_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/gencode.v37.annotation.gtf.gz"
params.gtf_name = "GENCODE.v37"

//define aligner to build references for
params.build_hisat2=true

//parse veriables
fasta_loc = params.fasta_loc
fasta_name = params.fasta_name
gtf_loc = params.gtf_loc
gtf_name = params.gtf_name
build_hisat2 = params.build_hisat2

//define fixed files
script_fetchFile = Channel.fromPath("../scripts/fetchFiles.sh")

//distribute fixed files
script_fetchFile.into{
    script_fetchFile_fasta
    script_fetchFile_gtf
}

log.info """\
==================
    ╔═╗╦ ╦╦ ╦    
    ║ ╦╠═╣╠═╣    
    ╚═╝╩ ╩╩ ╩    
==================
Reference Builder
==================
fasta:  ${params.fasta_name}
gtf:    ${params.gtf_name}
------------------
HISAT2: ${params.build_hisat2}
------------------
"""

/*
 download_fasta: downloads the fasta
 */
process download_fasta {
    tag "${fasta_name}"

    input:
        val fasta_loc
        file script_fetchFile from script_fetchFile_fasta

    output:
        tuple val(fasta_name), file('genome.fa.gz') into fasta

    script:
        """
        bash ${script_fetchFile} -t fasta -l ${fasta_loc}
        """
}

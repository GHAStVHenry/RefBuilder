#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

//define input files
params.fasta_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/GRCh38.p13.genome.fa.gz"
params.fasta_name = "GRCh38.p13"
params.gtf_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/gencode.v37.annotation.gtf.gz"
params.gtf_name = "GENCODE.v37"

//define aligner to build references for
params.hisat2=true
params.star=true

//define fixed files
script_fetchFile = Channel.fromPath("../scripts/fetchFiles.sh")
script_hisat2Build = Channel.fromPath("../scripts/hisat2Build.sh")
script_starBuild = Channel.fromPath("../scripts/starBuild.sh")

log.info """\
=========
╔═╗╦ ╦╦ ╦   
║ ╦╠═╣╠═╣
╚═╝╩ ╩╩ ╩
=========

Reference Builder
=================
fasta:  ${params.fasta_name}
gtf:    ${params.gtf_name}
------------------
HISAT2: ${params.hisat2}
STAR:   ${params.star}
------------------
"""

inclued { genomeFetch_pipe, referenceBuild_pipe } from './modules/RefBuilder_modules'

workflow {
    genomeFetch_pipe( script_fetchFile, params.fasta_name, params.fasta_loc, params.gtf_name, params.gtf_loc)
    referenceBuild_pipe( script_hisat2Build, script_starBuild, hisat2, star, genomeFetch_pipe.out.fasta, genomeFetch_pipe.out.gtf )
}

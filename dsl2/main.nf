#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

//params.fasta_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/GRCh38.p13.genome.fa.gz"
//params.fasta_name = "GRCh38.p13"
//params.gtf_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/gencode.v37.primary_assembly.annotation.gtf.gz"
//params.gtf_name = "GENCODE.v37"
params.fasta_loc = "ftp://ftp.ensembl.org/pub/release-104/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz"
params.fasta_name = "Saccharomyces_cerevisiae.R64-1-1"
params.gtf_loc = "ftp://ftp.ensembl.org/pub/release-104/gtf/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.104.gtf.gz"
params.gtf_name = "Saccharomyces_cerevisiae.R64-1-1"

//define aligner to build references for
params.hisat2 = true
params.star = true
params.bwamem2 = true

//parse veriables
fasta_loc = Channel.fromPath(params.fasta_loc)
fasta_name = params.fasta_name
gtf_loc = Channel.fromPath(params.gtf_loc)
gtf_name = params.gtf_name
hisat2 = params.hisat2
star = params.star
bwamem2 = params.bwamem2

//define fixed files
script_testFile = Channel.fromPath("../scripts/testFiles.sh")
script_hisat2Build = Channel.fromPath("../scripts/hisat2Build.sh")
script_starBuild = Channel.fromPath("../scripts/starBuild.sh")
script_bwamem2Build = Channel.fromPath("../scripts/bwamem2Build.sh")

log.info """\
=========
╔═╗╦ ╦╦ ╦   
║ ╦╠═╣╠═╣
╚═╝╩ ╩╩ ╩
=========

Reference Builder
=================
fasta:  	${params.fasta_name}
gtf:    	${params.gtf_name}
------------------
HISAT2: 	${params.hisat2}
STAR:   	${params.star}
bwa-mem2:	${params.bwamem2}
------------------
"""

include { genomeFetch_pipe; referenceBuild_pipe } from './modules/RefBuilder_modules'

workflow {
    genomeFetch_pipe( script_testFile, fasta_name, fasta_loc, gtf_name, gtf_loc)
    referenceBuild_pipe( script_hisat2Build, script_starBuild, script_bwamem2Build, hisat2, star, bwamem2, genomeFetch_pipe.out.fasta, genomeFetch_pipe.out.gtf )
}

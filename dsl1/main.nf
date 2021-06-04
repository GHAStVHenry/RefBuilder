#!/usr/bin/env nextflow

//define input files
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

//distribute fixed files
script_testFile.into{
    script_testFile_fasta
    script_testFile_gtf
}

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

/*
 download_fasta: downloads the fasta
 */
process test_fasta {
    tag "${fasta_name}"

    input:
        path script_testFile from script_testFile_fasta
        path fasta_loc

    output:
        tuple val(fasta_name), file('genome.fa.gz') into fasta

    script:
        """
        bash ${script_testFile} -t fasta -l ${fasta_loc}
        """
}

/*
 download_gtf: downloads the gtf
 */
process test_gtf {
    tag "${gtf_name}"

    input:
        path script_testFile from script_testFile_gtf
        path gtf_loc

    output:
        tuple val(gtf_name), file('genome.gtf.gz') into gtf

    script:
        """
        bash ${script_testFile} -t gtf -l ${gtf_loc}
        """
}

//distribute fasta and gtf files to different build processes
fasta.into{
    fasta_hisat2
    fasta_star
    fasta_bwamem2
}
gtf.into{
    gtf_hisat2
    gtf_star
}

/*
 build_hisat2: build HISAT2 references
  */
process build_hisat2 {
    tag "${fasta_name}"

    input:
        path script_hisat2Build
        tuple val(name_fasta), path(fasta) from fasta_hisat2
        tuple val(name_gtf), path(gtf) from gtf_hisat2

    output:
        path "hisat2/*" into ref_hisat2
    
    when:
        hisat2
    
    script:
        """
        bash ${script_hisat2Build} -f ${fasta} -g ${gtf}
        """
}

/*
 build_star: build STAR references
  */
process build_star {
    tag "${fasta_name}"

    input:
        path script_starBuild
        tuple val(name_fasta), path(fasta) from fasta_star
        tuple val(name_gtf), path(gtf) from gtf_star

    output:
        path "star/*" into ref_star

    when:
        star
    
    script:
        """
        bash ${script_starBuild} -f ${fasta} -g ${gtf}
        """
}

/*
 build_bwamem2: build bwa-mem2 references
  */
process build_bwamem2 {
    tag "${fasta_name}"

    input:
        path script_bwamem2Build
        tuple val(name_fasta), path(fasta) from fasta_bwamem2

    output:
        path "bwamem2/*" into ref_bwamem2

    when:
        bwamem2
    
    script:
        """
        bash ${script_bwamem2Build} -f ${fasta}
        """
}

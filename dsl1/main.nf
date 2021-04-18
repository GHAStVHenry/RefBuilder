#!/usr/bin/env nextflow

//define input files
params.fasta_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/GRCh38.p13.genome.fa.gz"
params.fasta_name = "GRCh38.p13"
params.gtf_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/gencode.v37.annotation.gtf.gz"
params.gtf_name = "GENCODE.v37"

//define aligner to build references for
params.hisat2=true
params.star=true

//parse veriables
fasta_loc = params.fasta_loc
fasta_name = params.fasta_name
gtf_loc = params.gtf_loc
gtf_name = params.gtf_name
hisat2 = params.hisat2
star = params.star

//define fixed files
script_fetchFile = Channel.fromPath("../scripts/fetchFiles.sh")
script_hisat2Build = Channel.fromPath("../scripts/hisat2Build.sh")

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
HISAT2: ${params.hisat2}
STAR:   ${params.star}
------------------
"""

/*
 download_fasta: downloads the fasta
 */
process download_fasta {
    tag "${fasta_name}"

    input:
        val fasta_loc
        path script_fetchFile from script_fetchFile_fasta

    output:
        tuple val(fasta_name), file('genome.fa.gz') into fasta

    script:
        """
        bash ${script_fetchFile} -t fasta -l ${fasta_loc}
        """
}

/*
 download_gtf: downloads the gtf
 */
process download_gtf {
    tag "${gtf_name}"

    input:
        val gtf_loc
        path script_fetchFile from script_fetchFile_gtf

    output:
        tuple val(gtf_name), file('genome.gtf.gz') into gtf

    script:
        """
        bash ${script_fetchFile} -t gtf -l ${gtf_loc}
        """
}

//distribute fasta and gtf files to different build processes
fasta.into{
    fasta_hisat2
    fasta_star
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
        tuple val(name_fasta), path(fasta) from fasta_hisat2
        tuple val(name_gtf), path(gtf) from gtf_hisat2
        path script_hisat2Build

    output:
        path "hisat2/*" into ref_hisat2
    
    when:
        hisat2
    
    script:
        """
        bash hisat2Build.sh
        """
}

/*
 build_star: build STAR references
  */
process build_star {
    tag "${fasta_name}"

    input:
        tuple val(name_fasta), path(fasta) from fasta_star
        tuple val(name_gtf), path(gtf) from gtf_star

    output:
        path "star/*" into ref_star

    when:
        star
    
    script:
        """
mkdir -p star

#gunzip files
echo "LOG: gunzipping fasta" &
gunzip ${fasta} &
echo "LOG: gunzipping gtf" &
gunzip ${gtf} &

#build the STAR reference
wait
echo "LOG: building reference"
STAR --runThreadN \$(nproc) --runMode genomeGenerate --genomeFastaFiles genome.fa --sjdbGTFFile genome.gtf --genomeDir star
        """
}
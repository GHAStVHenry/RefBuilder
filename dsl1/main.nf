#!/usr/bin/env nextflow

//define input files
params.fasta_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/GRCh38.p13.genome.fa.gz"
params.fasta_name = "GRCh38.p13"
params.gtf_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/gencode.v37.annotation.gtf.gz"
params.gtf_name = "GENCODE.v37"

//define aligner to build references for
params.hisat2=true

//parse veriables
fasta_loc = params.fasta_loc
fasta_name = params.fasta_name
gtf_loc = params.gtf_loc
gtf_name = params.gtf_name
hisat2 = params.hisat2

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
HISAT2: ${params.hisat2}
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

/*
 build_hisat2: build HISAT2 references
  */
process build_hisat2 {
    tag "${fasta_name}"

    input:
        tuple val(name_fasta), path(fasta) from fasta
        tuple val(name_gtf), path(gtf) from gtf

    output:
        path "hisat2/*" into ref_hisat2
    
    when:
        hisat2
    
    script:
        """
        mkdir -p temp
        mkdir -p hisat2

        #build the splice-site file
        echo "LOG: bulding the splice-site file"
	    hisat2_extract_splice_sites.py ${gtf} > ./tmp/genome.ss &

	    #build the exon file
        echo "LOG: building the exon file"
	    hisat2_extract_exons.py ${gtf}  >./tmp/genome.exon &

	    #build the HISAT2 reference
	    wait
        echo "LOG: building reference"
	    hisat2-build -p \$(nproc) --ss ./tmp/genome.ss --exon ./tmp/genome.exon ${fasta} hisat2/genome
        """
}
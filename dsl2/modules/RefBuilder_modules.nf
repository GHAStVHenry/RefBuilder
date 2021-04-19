/*
 download_fasta: downloads the fasta
 */
process download_fasta {
    tag "${fasta_name}"

    input:
        path script_fetchFile
        val fasta_loc

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
        path script_fetchFile
        val gtf_loc

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
        path script_hisat2Build
        tuple val(name_fasta), path(fasta)
        tuple val(name_gtf), path(gtf)

    output:
        path "hisat2/*" into ref_hisat2
    
    when:
        hisat2
    
    script:
        """
        bash hisat2Build.sh -f ${fasta} -g ${gtf}
        """
}

/*
 build_star: build STAR references
  */
process build_star {
    tag "${fasta_name}"

    input:
        path script_starBuild
        tuple val(name_fasta), path(fasta)
        tuple val(name_gtf), path(gtf)

    output:
        path "star/*" into ref_star

    when:
        star
    
    script:
        """
        bash starBuild.sh -f ${fasta} -g ${gtf}
        """
}

workflow genomeFetch_pipe {
    take:
        script_fetchFile
        fasta_name
        fasta_loc
        gtf_name
        gtf_loc

    main:
        download_fasta( script_fetchFile, fasta_name, fasta_loc )
        download_gtf( script_fetchFile, gtf_name, gtf_loc )

    emit:
        fasta = download_fasta.out
        gtf = download_gtf.out
}

workflow referenceBuild_pipe {
    take:
        script_hisat2Build
        script_starBuild
        hisat2
        star
        fasta_name
        fasta
        gtf

    main:
        build_hisat2( script_hisat2Build, hisat2, fasta_name, fasta, gtf )
        build_star( script_starBuild, star, fasta_name, fasta, gtf )

    emit:
        ref_hisat2 = build_hisat2.out
        ref_star = build_star.out
}

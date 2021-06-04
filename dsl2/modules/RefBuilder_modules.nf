/*
 fastaTest: downloads the fasta
 */
process fastaTest {
    tag "${fasta_name}"

    input:
        path script_testFile
        val fasta_name
        path fasta_loc

    output:
        tuple val(fasta_name), file('genome.fa.gz'), emit: fasta

    script:
        """
        bash ${script_testFile} -t fasta -l ${fasta_loc}
        """
}

/*
 gtfTest: downloads the gtf
 */
process gtfTest {
    tag "${gtf_name}"

    input:
        path script_testFile
        val gtf_name
        path gtf_loc

    output:
        tuple val(gtf_name), file('genome.gtf.gz'), emit: gtf

    script:
        """
        bash ${script_testFile} -t gtf -l ${gtf_loc}
        """
}

/*
 hisat2Build: build HISAT2 references
  */
process hisat2Build {
    tag "${name_fasta}"

    input:
        path script_hisat2Build
        val hisat2
        tuple val(name_fasta), path(fasta)
        tuple val(name_gtf), path(gtf)

    output:
        path "hisat2/*", emit: ref_hisat2
    
    when:
        hisat2
    
    script:
        """
        bash ${script_hisat2Build} -f ${fasta} -g ${gtf}
        """
}

/*
 starBuild: build STAR references
  */
process starBuild {
    tag "${name_fasta}"

    input:
        path script_starBuild
        val star
        tuple val(name_fasta), path(fasta)
        tuple val(name_gtf), path(gtf)

    output:
        path "star/*", emit: ref_star

    when:
        star
    
    script:
        """
        bash ${script_starBuild} -f ${fasta} -g ${gtf}
        """
}

/*
 bwamem2Build: build bwa-mem2 references
  */
process bwamem2Build {
    tag "${name_fasta}"

    input:
        path script_bwamem2Build
        val bwamem2
        tuple val(name_fasta), path(fasta)

    output:
        path "bwamem2/*", emit: ref_bwamem2

    when:
        bwamem2
    
    script:
        """
        bash ${script_bwamem2Build} -f ${fasta}
        """
}


workflow genomeFetch_pipe {
    take:
        script_testFile
        fasta_name
        fasta_loc
        gtf_name
        gtf_loc

    main:
        fastaTest( script_testFile, fasta_name, fasta_loc )
        gtfTest( script_testFile, gtf_name, gtf_loc )

    emit:
        fasta = fastaTest.out
        gtf = gtfTest.out
}

workflow referenceBuild_pipe {
    take:
        script_hisat2Build
        script_starBuild
        script_bwamem2Build
        hisat2
        star
        bwamem2
        fasta
        gtf

    main:
        hisat2Build( script_hisat2Build, hisat2, fasta, gtf )
        starBuild( script_starBuild, star, fasta, gtf )
        bwamem2Build( script_bwamem2Build, star, fasta )

    emit:
        ref_hisat2 = hisat2Build.out
        ref_star = starBuild.out
        ref_bwamem2 = bwamem2Build.out
}

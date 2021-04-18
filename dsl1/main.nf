#!/usr/bin/env nextflow

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

//define input files
params.fasta_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/GRCh38.p13.genome.fa.gz"
params.fastq_name = "GRCh38.p13"
params.gtf_loc = "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/gencode.v37.annotation.gtf.gz"
params.gtf_name = "GENCODE.v37"

//defines aligner to build references for
params.build_hisat2=true

//parse veriables
fasta_loc = params.fasta_loc
fasta_name = params.fasta_name
gtf_loc = params.gtf_loc
gtf_name = params.gtf_name
build_hisat2 = params.build_hisat2

/*
 download_fasta: downloads the fasta
 */
process download_fasta {
    tag "${fasta_name}"

    input:
        val fasta_loc

    output:
        tuple val(fasta_name), file('genome.fa.gz') into fasta

    script:
        """
        echo "LOG: testing location"
        wget --spider ${fasta_loc} 2> downloadTest.log
        if grep -q "connected" downloadTest.log
        then
            echo "LOG: url host exists"
            if grep -q "File .* exists" downloadTest.log
            then
                echo "LOG: file does exists"
                source="url"
            else
                echo "LOG: file does not exist"
                exit 1
            fi
        else
            if grep -q "failed: Name or service not known" downloadTest.log
            then
                echo "LOG: url host does not exist"
                exit 1
            else
                if grep -q "Scheme missing" downloadTest.log
                then
                    echo "LOG: not a valid"
                    if [ -d \$(dirname ${fasta_loc}) ]
                    then
                        echo "LOG: local folder exists"
                        if [ -f ${fasta_loc} ]
                        then
                            echo "LOG: local file exists"
                            source="local"
                        else
                            echo "LOG: local file does not exist"
                            exit 1
                        fi
                    else
                        echo "LOG: local folder does not exist"
                        exit 1
                    fi
                fi
            fi
        fi

        echo "LOG: testing filename"
        file=\$(basename ${fasta_loc})
        if [ "\${file: -2}" == "gz" ]
        then
            echo "LOG: gzip extension detected"
            gz=true
            if [ "\${file: -5:-3}" == "fa" ] || [ "\${file: -8:-3}" == "fasta" ]
            then
                echo "LOG: fasta extension detected"
                fa=true
            else
                echo "LOG: fasta extension not detected"
                exit 1
            fi
        else
            if [ "\${file: -2}" == "fa" ] || [ "\${file: -5}" == "fasta" ]
            then
                echo "LOG: fasta extension detected"
                fa=true
            else
                echo "LOG: fasta extension not detected"
                exit 1
            fi
        fi

        echo "LOG: fetching file"
        if [ "\${source}" == "url" ]
        then
            echo "LOG: downloading file"
            wget ${fasta_loc}
        elif [ "\${source}" == "local" ]
        then
            echo "LOG: copying file"
            cp ${fasta_loc} ./
        else
            echo "LOG: unexpected error - unknown source code"
        fi

        if [ \${gz} ]
        then
            if gzip -t \${file}
            then
                echo "LOG: gzip passed integrity test"
                mv \${file} genome.fa.gz
                echo "LOG: file renamed"
            else
                echo "LOG: gzip failed integrity test"
                exit 1
            fi
        else
            gzip -c \${file} > genome.fa.gz
            echo "LOG: file zipped and renamed"
        fi

        if [ "\$(zcat genome.fa.gz | head -n1 | head -c 1)" == ">" ]
        then
            echo "LOG: first line of file does contain header"
        else
            echo "LOG: first line of file does not contain header"
            exit 1
        fi
        """
}

#!/bin/bash -eufxv -o pipefail

script_name="hisat2Build.sh"

#help function
usage() {
  echo "-h  help documentation for $script_name"
  echo "-f  fasta file location (gzipped)"
  echo "-g  gtf file location (gzipped)"
  echo "Example: $script_name -f genome.fa.gz -g genome.gtf.gz"
  exit 1
}

main(){
    #parse options
    OPTIND=1
    while getopts :f:g:h opt
        do
            case $opt in
                f) fasta=$OPTARG;;
                g) gtf=$OPTARG;;
                h) usage;;
            esac
        done

    shift $(($OPTIND -1))

    #check for mandatory options
    if [[ -z ${fasta}} ]] || [[ -z ${gtf} ]]
    then
        usage
    fi

    mkdir -p hisat2

    #gunzip files
    echo "LOG: gunzipping fasta" &
    gunzip -c ${fasta} > genome.fa &
    echo "LOG: gunzipping gtf" &
    gunzip -c ${gtf} > genome.gtf &

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
}

main "$@"

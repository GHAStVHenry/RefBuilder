#!/bin/bash -eufxv -o pipefail

script_name="starBuild.sh"

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

    mkdir -p star

    #gunzip files
    echo "LOG: gunzipping fasta" &
    gunzip ${fasta} &
    echo "LOG: gunzipping gtf" &
    gunzip ${gtf} &

    #build the STAR reference
    wait
    echo "LOG: building reference"
    STAR --runThreadN $(nproc) --runMode genomeGenerate --genomeFastaFiles genome.fa --sjdbGTFfile genome.gtf --genomeDir star
}

main "$@"

#!/bin/bash -eufxv -o pipefail

script_name="bwamem2Build.sh"

#help function
usage() {
  echo "-h  help documentation for $script_name"
  echo "-f  fasta file location (gzipped)"
  echo "Example: $script_name -f genome.fa.gz"
  exit 1
}

main(){
    #parse options
    OPTIND=1
    while getopts :f:h opt
        do
            case $opt in
                f) fasta=$OPTARG;;
                h) usage;;
            esac
        done

    shift $(($OPTIND -1))

    #check for mandatory options
    if [[ -z ${fasta}} ]]
    then
        usage
    fi

    mkdir -p bwamem2

    #gunzip files
    echo "LOG: gunzipping fasta"
    gunzip ${fasta}

    #build the bwa-mem2 reference
    echo "LOG: building reference"
    bwa-mem2 index genome.fa

    #move the bwa-mem2 reference to output folder
    echo "LOG: move reference to output folder
    cp genome.fa* ./bwamem2/
}

main "$@"

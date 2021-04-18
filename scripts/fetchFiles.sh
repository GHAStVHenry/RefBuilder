#!/bin/bash

script_name="fetchFiles.sh"

#help function
usage() {
  echo "-h  help documentation for $script_name"
  echo "-t  file type (fasta or gtf)"
  echo "-l  location"
  echo "Example: $script_name -t fasta -l ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_37/GRCh38.p13.genome.fa.gz"
  exit 1
}

main(){
    #parse options
    OPTIND=1
    while getopts :t:l:h opt
        do
            case $opt in
                t) type=$OPTARG;;
                l) loc=$OPTARG;;
                h) usage;;
            esac
        done

    shift $(($OPTIND -1))

    #check for mandatory options
    if [[ -z ${type}} ]] || [[ -z ${loc} ]]
    then
        usage
    fi

    #test location
    echo "LOG: testing location"
    wget --spider ${loc} 2> downloadTest.log
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
                if [ -d $(dirname ${loc}) ]
                then
                    echo "LOG: local folder exists"
                    if [ -f ${loc} ]
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

    #test filename
    echo "LOG: testing filename"
    file=$(basename ${loc})
    if [ "${file: -2}" == "gz" ]
    then
        echo "LOG: gzip extension detected"
        gz=true
        if [ "${type}" == "fasta" ] && ([ "${file: -5:-3}" == "fa" ] || [ "${file: -8:-3}" == "fasta" ])
        then
            echo "LOG: fasta extension detected"
            ext=true
        elif [ "${type}" == "fasta" ] && [ "${file: -5:-3}" != "fa" ] || [ "${file: -8:-3}" != "fasta" ]
        then
            echo "LOG: fasta extension not detected"
            exit 1
        elif [ "${type}" == "gtf" ] && [ "${file: -6:-3}" == "gtf" ]
        then
            echo "LOG: gtf extension detected"
            ext=true
        elif [ "${type}" == "gtf" ] && [ "${file: -6:-3}" != "gtf" ]
        then
            echo "LOG: gtf extension not detected"
            exit 1
        else
            echo "LOG: invalid file type selected"
            exit 1
        fi
    else
        if [ "${type}" == "fasta" ] && ([ "${file: -2}" == "fa" ] || [ "${file: -5}" == "fasta" ])
        then
            echo "LOG: fasta extension detected"
            ext=true
        elif [ "${type}" == "fasta" ] && [ "${file: -2}" != "fa" ] && [ "${file: -5}" != "fasta" ]
        then
            echo "LOG: fasta extension not detected"
            exit 1
        elif [ "${type}" == "gtf" ] && ([ "${file: -3}" == "gtf" ]
        then
            echo "LOG: gtf extension detected"
            ext=true
        elif [ "${type}" == "gtf" ] && ([ "${file: -3}" != "gtf" ]
        then
            echo "LOG: gtf extension not detected"
            exit 1
        else
            echo "LOG: invalid file type selected"
            exit 1
        fi
    fi

    #fetch file
    echo "LOG: fetching file"
    if [ "${source}" == "url" ]
    then
        echo "LOG: downloading file"
        wget ${loc}
    elif [ "${source}" == "local" ]
    then
        echo "LOG: copying file"
        cp ${loc} ./
    else
        echo "LOG: unexpected error - unknown source code"
    fi

    #rename file (and gzip if necessary)
    if [ ${gz} ]
    then
        if gzip -t ${file}
        then
            echo "LOG: gzip passed integrity test"
            mv ${file} genome.fa.gz
            echo "LOG: file renamed"
        else
            echo "LOG: gzip failed integrity test"
            exit 1
        fi
    else
        gzip -c ${file} > genome.fa.gz
        echo "LOG: file zipped and renamed"
    fi

    #basic file type test
    if [ "${type}" == "fasta" ] && [ "$(zcat genome.fa.gz | head -n1 | head -c 1)" == ">" ]
    then
        echo "LOG: first line of fasta file does contain header"
    elif [ "${type}" == "gtf" ]
    then
        echo "LOG: gtf file format not tested"
    else
        echo "LOG: file format does not match standard"
        exit 1
    fi
}

main "$@"

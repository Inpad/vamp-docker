#!/usr/bin/env bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

reset=`tput sgr0`
green=`tput setaf 2`
yellow=`tput setaf 3`

version="0.8.0"
target='target/docker'

cd ${dir}

function parse_command_line() {
    flag_help=0
    flag_list=0
    flag_clean=0
    flag_make=0
    flag_build=0

    for key in "$@"
    do
    case ${key} in
        -h|--help)
        flag_help=1
        ;;
        -l|--list)
        flag_list=1
        ;;
        -c|--clean)
        flag_clean=1
        ;;
        -m|--make)
        flag_make=1
        ;;
        -b|--build)
        flag_make=1
        flag_build=1
        ;;
        *)
        ;;
    esac
    done
}

function help() {
    echo "${green}Usage of $0:${reset}"
    echo "${yellow}  -h|--help   ${green}Help.${reset}"
    echo "${yellow}  -l|--list   ${green}List all available images.${reset}"
    echo "${yellow}  -c|--clean  ${green}Remove all available images.${reset}"
    echo "${yellow}  -m|--make   ${green}Copy all available Docker files to '${target}' directory.${reset}"
    echo "${yellow}  -b|--build  ${green}Build all available images.${reset}"
}

function docker_rmi {
    echo "${green}removing docker image: $1 ${reset}"
    docker rmi -f $1 2> /dev/null
}

function docker_make {
    make_file=${dir}/$1/make.sh
    if [ -f "${make_file}" ]
    then
        echo "${green}executing make.sh from $1 ${reset}"
        bash ${dir}/$1/make.sh ${dir}/${target}/$1
    else
        echo "${green}copying files from: $1 ${reset}"
        cp -R ${dir}/$1 ${target} 2> /dev/null
    fi
}

function docker_build {
    echo "${green}building docker image: $1 ${reset}"
    docker build -t $1 $2
}

function docker_images {
    arr=$1[@]
    images=("${!arr}")
    pattern=$(printf "\|%s" "${images[@]}")
    pattern=${pattern:2}
    echo "${green}built images:${yellow}"
    docker images | grep 'magneticio/vamp' | grep ${pattern}
}

function process() {
    rm -Rf ${dir}/${target} 2> /dev/null && mkdir -p ${target}

    regex="^${dir}\/(.+)\/Dockerfile$"
    images=()

    for file in `find ${dir} | grep Dockerfile`
    do
      [[ ${file} =~ $regex ]] && [[ ${file} != *"/"* ]]
        image_dir="${BASH_REMATCH[1]}"

        if [[ ${image_dir} != *"/"* ]]; then

            image=vamp-${image_dir}
            images+=(${image})
            image_name=magneticio/${image}:${version}

            if [ ${flag_make} -eq 1 ]; then
                docker_make ${image_dir}
            fi
            if [ ${flag_clean} -eq 1 ]; then
                docker_rmi ${image_name}
            fi
            if [ ${flag_build} -eq 1 ]; then
                docker_build ${image_name} ${dir}/${target}/${image_dir}
            fi
        fi
    done

    if [ ${flag_list} -eq 1 ]; then
        docker_images images
    fi

    echo "${green}done.${reset}"
}

parse_command_line $@

if [ ${flag_help} -eq 1 ] || [[ $# -eq 0 ]]; then
    help
fi

if [ ${flag_list} -eq 1 ] || [ ${flag_clean} -eq 1 ] || [ ${flag_make} -eq 1 ] || [ ${flag_build} -eq 1 ]; then
    process
fi

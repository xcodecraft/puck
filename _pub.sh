#!/bin/bash
CUR_DIR=$(cd "$(dirname "$0")"; pwd)
source $CUR_DIR/conf.sh
cd $CUR_DIR

function usage() {
    echo "usage: $0 --prj_group prj_group --prj project_name --tag project_tag [--deploy_to deploy_dir] --host host_list(develop|testing|production)  "
 }

while [ "$1" != "" ]; do
    case $1 in
        --prj_group )      shift
                           prj_group=$1
                           ;;
        --prj )           shift
                           project_name=$1
                           ;;

        --tag )            shift
                           project_tag=$1
                           ;;

        --deploy_to )      shift
                           deploy_to=$1
                           ;;

        --host )           shift
                           host_list=${1:-'develop'}
                           ;;
        -h | --help )      usage
                           exit
                           ;;
        * )                usage
                           exit 1
    esac
    shift
done

host_list=${host_list:-'develop'}


if [ "$prj_group" = "" ] ; then
    prj_group=$DEFAULT_PRJ_GROUP
fi

if [  "$project_tag" = "" ]; then
    usage
    exit
fi


echo $(tput setaf 2) "---> 开始部署项目：" $(tput setaf 5) $project_name
echo $(tput setaf 2) "---> 版本号：" $(tput setaf 5) $project_tag
echo $(tput setaf 2) "---> 机器列表：" $(tput setaf 5) $host_list

pub_plan_path=$RELEASE_BASEPATH/${prj_group}_pub/${project_name}
extend_vars=`cat ${pub_plan_path}/vars.yml 2>/dev/null|wc -l`
if [ $extend_vars -gt 0 ]
then
    with_extend_vars_file="--extra-var @${pub_plan_path}/vars.yml"
fi
ansible-playbook -i $pub_plan_path/hosts src/pub.yml  $with_extend_vars_file --extra-var "user=${USER} deploy_to=${deploy_to} remote_user=${DEFAULT_REMOTE_USER} host=${host_list} project_version=${project_tag}  project_name=${project_name}"  --ask-become-pass

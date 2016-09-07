#!/bin/bash
CUR_DIR=$(cd "$(dirname "$0")"; pwd)
source $CUR_DIR/conf.sh
cd $CUR_DIR

function usage() {
    echo "usage: $0 --prj_group prj_group --prj project_name  --online_tag online_tag --tag project_tag  --host host_list(dev|demo|online) [ --deploy_to  deploy_dir] "
}

while [ "$1" != "" ]; do
    case $1 in
        --prj_group )      shift
                           prj_group=$1
                           ;;
        --prj )           shift
                           project_name=$1
                           ;;

        --online_tag )     shift
                           online_tag=$1
                           ;;
        --tag )            shift
                           project_tag=$1
                           ;;

        --host )           shift
                           host_list=${1:-'dev'}
                           ;;
        --deploy_to )      shift
                           deploy_to=$1
                           ;;
        -h | --help )      usage
                           exit
                           ;;
        * )                usage
                           exit 1
    esac
    shift
done
host_list=${host_list:-'dev'}



if [  "$online_tag" = "" ]; then
    usage
    exit
fi
if [  "$project_tag" = "" ]; then
    usage
    exit
fi


echo $(tput setaf 2) "---> 开始更新项目：" $(tput setaf 5) $project_name
echo $(tput setaf 2) "---> 线上版本号：" $(tput setaf 5) $online_tag
echo $(tput setaf 2) "---> 待更新版本号：" $(tput setaf 5) $project_tag
echo $(tput setaf 2) "---> 机器列表：" $(tput setaf 5) $host_list
pub_plan_path=$RELEASE_BASEPATH/${prj_group}-pub/projects/${project_name}
extend_vars=`cat ${pub_plan_path}/vars.yml 2>/dev/null|wc -l`
if [ $extend_vars -gt 0 ]
then
    with_extend_vars_file="--extra-var @${pub_plan_path}/vars.yml"
fi
ansible-playbook -i $pub_plan_path/hosts src/patch.yml  $with_extend_vars_file --extra-var "user=${USER} deploy_to=${deploy_to} remote_user=$DEFAULT_REMOTE_USER host=${host_list} project_version=${project_tag} online_version=${online_tag} project_name=${project_name}"  --ask-become-pass

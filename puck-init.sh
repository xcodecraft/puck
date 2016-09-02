#!/bin/bash
export PATH=.:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/usr/local/bin
CUR_DIR=$(cd "$(dirname "$0")"; pwd)
source $CUR_DIR/conf.sh
cd $CUR_DIR

function usage() {
    echo "usage: $0 [--prj_group prj_group] --prj prj --host host_list(dev|demo|online...)"
}

while [ "$1" != "" ]; do
    case $1 in
        --prj_group )      shift
                           prj_group=$1
                           ;;
        --prj )           shift
                           prj=$1
                           ;;
        --host )           shift
                           host_list=$1
                           ;;
        -h | --help )      usage
                           exit
                           ;;
        * )                usage
                           exit 1
    esac
    shift
done

if [ "$prj" = "" ] ; then
    usage
    exit 1
fi
if [ "$prj_group" = "" ] ; then
    prj_group=$DEFAULT_PRJ_GROUP
fi
echo $(tput setaf 2) "---> 打通与待发布主机之间网络环境" $(tput setaf 5) $host_list
source $CUR_DIR/src/scripts/_base.sh
pub_plan_path=$RELEASE_BASEPATH/${prj_group}_pub/${prj}
ansible-playbook -i $pub_plan_path/hosts src/init.yml --extra-var "user=${USER} host=$host_list" -k

#!/bin/bash
export PATH=.:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/usr/local/bin
CUR_DIR=$(cd "$(dirname "$0")"; pwd)
source $CUR_DIR/conf.sh
cd $CUR_DIR

function usage() {
    echo "usage: $0 [--prj_group prj_group] --prj prj [--tag project_tag] [--dest deploy_dir] [--git git_repo] --host host_list(dev|demo|online...) [-f] "
}

while [ "$1" != "" ]; do
    case $1 in
        --prj_group )      shift
                           prj_group=$1
                           ;;
        --prj )           shift
                           prj=$1
                           ;;

        --tag )            shift
                           project_tag=$1
                           ;;
        --dest )           shift
                           deploy_to=$1
                           ;;
        --git )           shift
                           git_repo=$1
                           ;;

        -f )            shift
                           force=1
                           ;;

        --host )           shift
                           host_list=${1:-'dev'}
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

if [ "$prj" = "" ] ; then
    usage
    exit 1
fi
if [ "$prj_group" = "" ] ; then
    prj_group=$DEFAULT_PRJ_GROUP
fi
if [ "$git_repo" = "" ] ; then
    git_repo=${DEFAULT_GIT_REPO_BASE}$prj
fi
if [ "$deploy_to" = "" ] ; then
    deploy_to=${DEFAULT_DEPLOY_DIR}
fi
echo $(tput setaf 2) "---> 开始部署项目：" $(tput setaf 5) $prj
echo $(tput setaf 2) "---> 机器列表：" $(tput setaf 5) $host_list
source $CUR_DIR/src/scripts/_base.sh
source $CUR_DIR/src/scripts/_puck.sh

#更新项目组发布计划
get_group_pub_plan $prj_group
#待发布项目初始化
init $prj $git_repo
#选择待发布版本
NEW_VER=$project_tag
chose_ver $prj
if [ -z $force ]
then
    #与线上版本进行比较
    online_ver=`get_online_ver $prj_group $prj $host_list $deploy_to`
    if [ -z $online_ver ]
    then
        need_pub=2
    else
        diff_vers $prj $online_ver $NEW_VER
        #返回值判断
        #    0  没有版本变化，无需发布
        #   -1  版本对比期间出错
        #    1  无系统资源变化，只需patch
        #    2  有系统资源变化，建议pub
        need_pub=$?
    fi
else
    need_pub=2
fi
cd $CUR_DIR
export CRYPTOGRAPHY_ALLOW_OPENSSL_098=1
if [ $need_pub = 2 ]
then
    mk_pub $prj $NEW_VER
    echo $(tput setaf 2) "---> PUB -----"
    bash ${CUR_DIR}/_pub.sh --prj_group $prj_group --prj $prj --tag $NEW_VER --host $host_list --deploy_to $deploy_to
elif [ $need_pub = 1 ]
then
    mk_patch $prj $online_ver $new_ver
    echo $(tput setaf 2) "---> PATCH -----"
    bash ${CUR_DIR}/_patch.sh --prj_group $prj_group  --prj $prj --online_tag $online_ver --tag $NEW_VER --host $host_list --deploy_to $deploy_to
else
    echo $(tput setaf 2) "---> Do nothing -----"
fi

#!/bin/bash
#update project code
function get_group_pub_plan()
{
    prj_group=$1
    if [ -d $RELEASE_BASEPATH/${prj_group}-pub ]
    then
        cd $RELEASE_BASEPATH/${prj_group}-pub
        git pull > /dev/null
    else
        cd $RELEASE_BASEPATH/
        git clone $DEFAULT_GIT_REPO_BASE${prj_group}-pub > /dev/null
    fi

}
function _get_project()
{
    prj=$1
    git=$2
    if [ -d $RELEASE_BASEPATH/$prj ]
    then
        cd $RELEASE_BASEPATH/$prj
        git fetch
    else
        cd $RELEASE_BASEPATH/
        git clone $git
    fi
}
function init()
{
    prj=$1
    git=$2
    mkdir -p $RELEASE_BASEPATH
    mkdir -p $PATCH_BASEPATH/$prj
    mkdir -p $RELEASE_BASEPATH/pkgs/$prj
    _get_project $prj $git
}
function get_online_ver()
{
    prj_group=$1
    prj=$2
    host=$3
    deploy_to=$4
    cd $RELEASE_BASEPATH/${prj_group}-pub/projects/$prj
    host=`grep "\[$host\]" hosts -A 1|grep -v $host|grep -v grep`
    ssh $host "cat $deploy_to/$prj/version.txt" 2>/dev/null
}
function chose_ver()
{
    prj=$1
    if [ ! -z $NEW_VER ]
    then
        return
    else
        cd $RELEASE_BASEPATH/$prj
        #list recent tags
        tags=(`git tag |tail -n 10|sort -nr`)
        i=1
        cecho "=== === === === 请选择版本 === === === ===" $c_title
        while [ $i -le ${#tags[@]} ]
        do
            echo $i")" ${tags[$i-1]}
            let i+=1
        done
        cecho "=== === === === 请输入序号：1~${#tags[@]} === === === ===" $c_title
        read num
        NEW_VER=${tags[$num-1]}
    fi
}
function get_ver()
{
    prj=$1
    ver=$2
    # 获取各个版本的代码
    cd $RELEASE_BASEPATH/$prj
    git archive --prefix=$ver/ --format=tar $ver| (cd $PATCH_BASEPATH/$prj && tar xf -)
}
function _bk_filename()
{
    tag="$online_ver-$new_ver"
    echo bk.$tag;
}
function _patch_filename()
{
    tag="$online_ver-$new_ver"
    echo patch.$tag;
}
function _diff()
{
    #   对比代码
    prefix=`echo "$new_ver" | awk '{ gsub("/","\\\/"); print $0"\\\/"; }'`
    diff_files=`diff -r --brief $new_ver $online_ver | grep -v "Only in ${online_ver}" | grep -v ".git" |  awk '{ if("Files"==$1) { print " "$2; }; if("Only"==$1) { print " "substr($3,1,length($3)-1)"/"$4 } }'| sed "s/$prefix//" `
    bk_files=`diff -r --brief $new_ver $online_ver | grep -v "Only in ${new_ver}" | grep -v ".git" |  awk '{ if("Files"==$1) { print " "$2; }; if("Only"==$1) { print " "substr($3,1,length($3)-1)"/"$4 } }'| sed "s/$prefix//"|sed "s/$online_ver\///" `

    echo $bk_files > $prj_path/`_bk_filename $prj $online_ver $new_ver`.txt

    for file in $diff_files
    do
        patch_files="${patch_files} ${file} "
    done
    echo $patch_files > $prj_path/`_patch_filename $prj $online_ver $new_ver`.txt
}
function _patch_or_pub()
{
    diff_files_cnt=0
    diff_file=`_patch_filename $prj $online_ver $new_ver`
    patch_files=`cat $prj_path/${diff_file}.txt`
    diff_files_cnt=`echo $patch_files| wc -w `

    if [ $diff_files_cnt -le 0 ];
    then
        cecho "对比的版本,没有任何变化 "  $c_error
        cecho "=== === 退出 === ===" $c_title
        return 0;
    fi

    cecho "=== 上传文件列表 === " $c_title
    no=0;
    files="";
    for file in $patch_files
    do
        no=`echo "$no + 1" | bc`
        cecho "[$no]:\t$file"  $c_file
    done
    deploy_confirm "确认文件列表？"
    if [ 1 != $? ]; then
        return -1;#cacel deployment
    fi

    deploy_confirm "是否进行文件diff展示 ？"
    if [ 1 = $? ]; then
        for file in $patch_files
        do
            #	确定文件类型，只针对 text 类型
            type=`file $new_ver/$file | grep "text"`
            if [ -z "$type" ]; then
                cecho "\t--- 非text文件 忽略对比 ---" $c_file
                continue
            fi
            diffs=`diff $new_ver/$file $online_ver/$file`
            #   如果没有不同就不要确认
            if [ -z "$diffs" ]; then
                cecho " ==== $file nothing different ==== " $c_notify
                continue
            fi
            #   进行 vimdiff
            vimdiff $new_ver/$file $online_ver/$file
            deploy_confirm "	修改确认 $file ?"
            if [ 1 != $? ]; then
                return -1;#cacel deployment
            fi
        done
    fi
    #判断是否有系统资源文件变更
    #有则pub；否则patch
    need_pub=`echo $patch_files|grep _rg |grep -v grep|wc -l`
    if [ $need_pub = 0 ]
    then
        return 1;
    else
        return 2;
    fi
}
## 0: no difference; -1: cacel; 1:has difference,should patch; 2: should pub
function diff_vers()
{
    prj=$1
    online_ver=$2
    new_ver=$3
    prj_path=$PATCH_BASEPATH/$prj

    cecho "=== === === === $prj diff online vs new tag === === === ===" $c_title
    cecho " ONLINE_VER => NEW_VER : [$online_ver] => [$new_ver]" $c_notify
    if [ $new_ver == $online_ver ]
    then
        cecho " 已经是最新版本了,您选择的版本和线上的版本是同一版本:[$new_ver] "  $c_error
        cecho "=== === 退出 === ===" $c_title
        return 0;
    fi
    get_ver $prj $online_ver
    get_ver $prj $new_ver
    cd $prj_path
    _diff
    _patch_or_pub
    return $?
}
function mk_patch()
{
    prj=$1
    online_ver=$2
    new_ver=$3
    prj_path=$PATCH_BASEPATH/$prj
    cd $prj_path
    #源文件打包
    cecho "=== patch文件打包 === " $c_notify
    diff_file=`_patch_filename $prj $online_ver $new_ver`
    patch_files=`cat $prj_path/${diff_file}.txt`
    patch_tgz="$prj_path/${diff_file}.tgz"
    tar cvfz $patch_tgz -C $new_ver/ $patch_files > /dev/null

    if [ ! -s "$patch_tgz" ]; then
        cecho "错误：文件打包失败" $c_error
        exit 1
    fi
    echo "patch tar:"$patch_tgz
}
function mk_pub()
{
    prj=$1
    new_ver=$2
    cd $RELEASE_BASEPATH/$prj
    git archive -o $RELEASE_BASEPATH/pkgs/$prj/$new_ver.tgz --format=tar $new_ver
    echo "pub tar:"$RELEASE_BASEPATH/pkgs/$prj/$new_ver.tgz
}


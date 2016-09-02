#!/bin/bash
export PATH=.:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/usr/local/bin


#	文件黑名单
BLACKLIST='(.*\.tmp$)|(.*\.log$)|(.*\.svn.*)|(.*\.git.*.)'

###########################################################################
#	公共库
#
export LC_ALL="zh_CN.UTF-8"
#	格式化输出
export black='\E[0m\c'
export boldblack='\E[1;0m\c'
export red='\E[31m\c'
export boldred='\E[1;31m\c'
export green='\E[32m\c'
export boldgreen='\E[1;32m\c'
export yellow='\E[33m\c'
export boldyellow='\E[1;33m\c'
export blue='\E[34m\c'
export boldblue='\E[1;34m\c'
export magenta='\E[35m\c'
export boldmagenta='\E[1;35m\c'
export cyan='\E[36m\c'
export boldcyan='\E[1;36m\c'
export white='\E[37m\c'
export boldwhite='\E[1;37m\c'

cecho()
{
	message=$1
	color=${2:-$black}

	echo -e "$color"
	echo -e "$message"
	tput sgr0			# Reset to normal.
	echo -e "$black"
	return
}

cread()
{
	color=${4:-$black}

	echo -e "$color"
	read $1 "$2" $3
	tput sgr0			# Reset to normal.
	echo -e "$black"
	return
}

#	确认用户的输入
deploy_confirm()
{
	while [ 1 = 1 ]
	do
		cread -p "$1 [y/n]: " CONTINUE $c_file
		if [ "y" = "$CONTINUE" ]; then
		  return 1;
		fi

		if [ "n" = "$CONTINUE" ]; then
		  return 0;
		fi
	done

	return 0;
}



###########################################################################

#	提示颜色
c_notify=$boldcyan
c_error=$boldred
c_title=$boldgreen
c_file=$boldyellow


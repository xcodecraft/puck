[TOC]
# 功能
> 基于ansible的代码发布工具

```
基于ssh协议，首次发布需打通发布机与目标机器的ssh信任关系（参见下文**首次使用**）
发布过程中，输入一次密码后并行发布代码到多台主机
```

工作任务流：
![工作流](http://p9.qhimg.com/t01fb727c885f0de836.png)

术语|解释
---|---
发布计划|开发人员制定的各IDC主机列表，详见下文**编写发布计划**
全量更新|每个工程使用单独的系统资源（如nginx配置、fpm配置等），重启系统资源
增量更新|只是代码的更新，不涉及系统资源的重启
拉取代码|目前仅支持从git中获取项目代码
版本|git tag

#用法
##首次使用

> 创建发布计划
> 打通发布机与目标机器的ssh信任关系
> 添加alias到自己的bashrc

### 编写发布计划
发布计划管理：
![prj-pub](http://p0.qhimg.com/t010e57d68f1bc4a8b2.png)

```
本版本使用git仓库管理各项目的发布计划
建议按业务线创建$prj_group
新增加$prj_group时，创建一个新的git仓库:${prj_group}-pub
新增加项目$prj时，在对应${prj_group}-pub工程中：
   mkdir -p projects/$prj
   touch hosts vars.yml
```

发布计划包括两个文件：

* hosts：主机组
* vars.yml：系统资源控制配置

#### hosts文件
由两部分组成：部署主机组、系统资源配置信息（可选）
示例：

```
[dev]
    w1.dev.test.com
[beta]
    beta1.dev.test.com
[online]
    w01.ol.test.com
    w02.ol.test.com
[dev:vars]
    before_rg= "stop,clean"
    after_rg="conf,start -e beta -s web"
[beta:vars]
    before_rg= "stop,clean"
    after_rg="conf,start -e beta -s web"
[online:vars]
    before_rg= "stop,clean"
    after_rg="conf,start -e online -s web"
```
如上，dev\beta\online为不同的主机组
dev:vars\beta:vars\online:vars为各主机组特定的系统资源配置
#### 系统资源配置信息
可选的系统资源配置信息|说明
---|---
after_cmd|全量更新后执行的脚本
before_rg|全量更新时，部署前执行的[rigger-ng](https://github.com/xcodecraft/rigger-ng)操作
after_rg|全量更新时，部署后执行的[rigger-ng](https://github.com/xcodecraft/rigger-ng)操作
#### vars.yml
系统资源配置信息同上
此处配置所有主机组共用的系统资源配置信息
示例：
```
after_cmd :  '/home/q/tools/rigger-ng/setup.sh  /home/q/tools/rigger-ng/src/etc/centos.py'
```
### 打通发布机与目标机器的ssh信任关系

```
puck-init --prj prj --host host_list(dev|online)
```
* prj 项目名称
* host_list hosts文件中定义的主机组

### 添加alias到bashrc
```shell
cat /home/q/tools/puck/bashrc >> ~/.bashrc
```

## 日常使用
```
puck [--prj_group prj_group] --prj prj [--tag project_tag] [--dest deploy_dir] [--git git_repo] --host host_list(dev|demo|online...) [-f]
```
* prj_group：项目组，默认值见conf.sh
* prj：项目
* tag：版本号
* dest：部署路径，默认值见conf.sh
* git：项目所在git地址，默认值为conf.sh中的${DEFAULT_GIT_REPO_BASE}\${prj}.git
* host：发布计划中的主机组
* f： 强制全量更新


# 补充说明

## 所有prj_group共用默认配置文件
cat conf.sh

```
#!/bin/bash
DEFAULT_DEPLOY_DIR="/data/x/projects"
DEFAULT_GIT_REPO_BASE="git@github.com:xcodecraft/"
DEFAULT_REMOTE_USER="xxx"
DEFAULT_PRJ_GROUP="xxx"
PATCH_BASEPATH=$HOME/release/patches
RELEASE_BASEPATH=$HOME/release
```

## git_repo
默认值为conf.sh中的${DEFAULT_GIT_REPO_BASE}\${prj}.git

## 强制发布
不进行代码比较，强制全量更新




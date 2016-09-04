[TOC]
# 功能
> 基于ansible的代码发布工具

工作任务流：

```flow
st=>start: 开始
e=>end: 结束
get_plan=>operation: 获取待发布工程的发布计划
get_prj=>operation: 获取工程源码
chose_ver=>operation: 选择待发布版本
diff_code=>operation: 与线上版本进行代码比较
need_pub=>condition: 全量更新or增量更新？
patch=>operation: 增量更新
pub=>operation: 全量更新
st->get_plan->get_prj->chose_ver->diff_code->diff_code->need_pub
need_pub(yes)->pub->e
need_pub(no)->patch->e
```
术语|解释
---|---
发布计划|开发人员制定的各IDC主机列表，详见下文**发布计划**
全量更新|每个工程使用单独的系统资源（如nginx配置、fpm配置等），重启系统资源
增量更新|只是代码的更新，不涉及系统资源的重启
拉取代码|目前仅支持从git中获取项目代码
版本|git tag

#用法
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

#补充说明
## 配置文件
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
## prj_group
项目组名称，对项目进行分组管理
默认值为配置文件中的DEFAULT_PRJ_GROUP

## git_repo
默认值为conf.sh中的${DEFAULT_GIT_REPO_BASE}\${prj}.git

## 发布计划
```
本版本隐形约定：
使用git仓库管理各项目的发布计划
一个项目组对应一个git仓库，名称为${prj_group}-pub
每个项目$prj的发布计划在${prj_group}-pub/projects/$prj中
```
发布计划包括两个文件：
* hosts：主机组
* vars.yml：系统资源控制配置

### hosts文件
由两部分组成：部署主机组、系统资源控制配置（可选）
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
如上，dev\beta\online为不同的主机组，我们可以通过--host dev/beta/online来发布到不同的主机组
dev:vars\beta:vars\online:vars为各主机组特定的系统资源
#### 系统资源配置选项
系统资源配置选项|说明
---|---
after_cmd|全量更新后执行的脚本
before_rg|全量更新时，部署前执行的[rigger-ng](https://github.com/xcodecraft/rigger-ng)操作
after_rg|全量更新时，部署后执行的[rigger-ng](https://github.com/xcodecraft/rigger-ng)操作
### vars.yml
系统资源配置选项同上
此处配置所有主机组执行的系统资源控制指令
## 强制发布
不进行代码比较，直接发布




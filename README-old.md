# 发布工具

# 用法

1. 在projects 目录下以项目名字新建目录:
    ```
    cd projects
    mkdir ayi_sdks
    ```

2. 新建文件 hosts 和 projectname-vars.yml

    hosts: 内含要发布的主机列表
    ```
    [develop]
        ip1
        ip2
        ...

    [testing]
        ip1
        ip2
        ...
    ```
    可以管理多组不同环境的主机列表。 develop 和tesing 为每组的主机名


   projectname-vars.yml 为项目的一些不轻易改动的信息，例如git 仓库地址,
   项目部署到的位置, 目前只需要填写几个变量：
   ```
   project_name: "ayi_sdks"
   deploy_to: "/data/htdocs"
   git_repo: "https://github.com/ayibang/ayi_sdks"
   ```
   可选项
   ```
   before_rg : "stop"
   after_rg  : "start -e {{host}} -s admin,api"
   after_cmd : "/data/x/projects/<you-project>/setup.sh"
   ```
   * before_rg  在实装前执行的rg 指令
   * after_rg   在安装后执行的rg 指令
   * after_cmd  在安装后执行的shell 脚本

3. 使用方法
 <del> ansible-playbook -i projects/ayi_sdks/hosts src/pub.yml  --extra-var @projects/ayi_sdks/vars.yml --extra-var 'host=develop project_version=0.0.1  project_name=ayi_sdk' -u 发布者用户 -k <del>

 ```
 rocket_pub.sh --prj ayi_sdk --tag 0.0.1 --host develop

alias rocket_pub.sh=rocket
 ```

    通过extra-var 传递每次发布可能需要变化的参数。传递与vars.yml 同名的变量，会覆盖vars.yml 里面的变量。



# changelog
add before_link_cmd support:   before_link_cmd: '/home/of/shell.sh -args'


# NewInstallScript-bash-
#### centos自动化配置（bash脚本）
#### 程序部署方法：

#### 1、将整个安装程序包NewInstallScript复制到待安装机器root目录下。
#### 2、进入待安装机器根目录下NewInstallScript目录，修改CONFIG.txt配置信息（只需更改IP）。
#### 3、执行：bash NewInstallScript.sh -h 可查看安装具体参数（-h: get help  -a: all thing -n: network & dns -y: install for yum -p: install for pip）
#### 4、静心等待程序执行完，程序执行结束后会询问是否需要删除源安装程序（y：删除安装包 n：保留）
#### 5、程序审理执行完之后会在待安装机器根目录下生成一个installLog.txt文件，里面学习记载了此次安装的反馈信息。**

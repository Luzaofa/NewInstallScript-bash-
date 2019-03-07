#! /bin/bash
echo "开始配置。。"


NETPATH="/root/NewInstallScript/ConfigurationFile/network/NETWORK.txt"
DNSPATH="/root/NewInstallScript/ConfigurationFile/network/DNS.txt"
LOGPATH="/root/installLog.txt"
YUMPATH="/root/NewInstallScript/ConfigurationFile/thirdpackages/yum.txt"
PIPPATH="/root/NewInstallScript/ConfigurationFile/thirdpackages/pip.txt"

datetime=$(date '+%Y-%m-%d %H:%M:%S')


if [ -f ${LOGPATH} ]
then
	rm ${LOGPATH}
fi

network_scripts(){
	echo $datetime "INFO 正在配置网络..." | tee -a ${LOGPATH}
	cd /etc/sysconfig/network-scripts/

	networkNames=$(ip a | grep 'UP qlen 1000')
        for name in ${networkNames}
        do
		upName=${name//:}
		if [[ ${upName} == eno* ]]
		then
			newUP=${upName}
			echo $datetime "INFO ${newUP}" | tee -a ${LOGPATH}
		fi
        done

	networkFiles=$(ls)
	for file in ${networkFiles}
	do
		if [[ ${file} == *${newUP} ]]
                then
			if [ -f ${file} ]
			then
				rm ${file}
			fi

			while read line
			do
				echo ${line} >> ${file}
				echo $datetime "INFO ${line}" >> ${LOGPATH}
			done < ${NETPATH}

			echo NAME="${newUP}" >> ${file}
			echo DEVICE="${newUP}" >> ${file}

			IP=$(grep "IPADDR" /root/NewInstallScript/CONFIG.txt)
			echo ${IP} >> ${file}
			echo $datetime "INFO ${IP}" >> ${LOGPATH}
			grep "GATEWAY" /root/NewInstallScript/CONFIG.txt >> ${file}
			grep "NETMASK" /root/NewInstallScript/CONFIG.txt >> ${file}
			cat ${file}
                fi
	done
	ifup ${newUP}
}

dns_scripts(){
	cd /etc/
	dnsfile="resolv.conf"
	if [ -f ${dnsfile} ]
        then
        	rm ${dnsfile}
	fi

        while read line
        do
        	echo ${line} >> ${dnsfile}
		echo $datetime "INFO ${line}" >> ${LOGPATH}
        done < ${DNSPATH}

        echo  $datetime "INFO 网络配置成功..." | tee -a ${LOGPATH}
}


kernel_install(){
	echo  $datetime "INFO 正在安装kernel..." | tee -a ${LOGPATH}
	yumvision=$(yum list installed | grep kernel)

        cd /root/NewInstallScript/ConfigurationFile/kernel/

	develmass=$(yum -y install kernel-devel-3.10.0-693.el7.x86_64.rpm)
	if [[ ${develmass} == *installed* ]]; then 
    		echo $datetime "INFO devel安装成功" | tee -a ${LOGPATH}
	fi
        headermass=$(yum -y install kernel-headers-3.10.0-693.el7.x86_64.rpm)
        if [[ ${headermass} == *installed* ]]; then
                echo $datetime "INFO header安装成功" | tee -a ${LOGPATH}
        fi

	num=1
	
	for V in ${yumvision}
	do
		if [[ ${num} -lt 3 ]];then
                	if [[ ${num} -eq 1 ]];then
				name=${V}
			else
				vision=${V}
			fi
			let num+=1
		else
			let num=1
			install=${V}
			#echo ${name}${vision}${install}

			# kernel安装前检测
			if [[ ${name} == kernel-devel.x86* ]] || [[ ${name} == kernel-headers.x86* ]];then
				
                        	if [[ ${vision} == 3.10.0-693.el7 ]];then
                                	echo $datetime "INFO ${name}版本不需要更改" | tee -a ${LOGPATH}
				else
					echo $datetime 'INFO 正在删除旧版本' | tee -a ${LOGPATH}
					yum -y remove ${name}
					cd /root/NewInstallScript/ConfigurationFile/kernel/
                                	newinstall=${name//.x86*}
					yum -y install ${newinstall}-3.10.0-693.el7.x86_64.rpm
				fi
			fi			
        		name=""
        		vision=""
        		install=""
		fi
	done
}

yum_install(){
	echo  $datetime "INFO 正在安装yum..." | tee -a ${LOGPATH}
	cd /etc/yum.repos.d/
	if [ ! -d bak ];then
		mkdir bak
	fi

	mv *.repo bak/
	cp /root/NewInstallScript/ConfigurationFile/yum/*.repo /etc/yum.repos.d/
	yum makecache fast

	file="/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7"
	if [ -f ${file} ];then
		mv ${file} ${file}.bak
	fi
	cp /root/NewInstallScript/ConfigurationFile/key/RPM-GPG-KEY-EPEL-7.ustc /etc/pki/rpm-gpg/
	cd /etc/pki/rpm-gpg/
	mv RPM-GPG-KEY-EPEL-7.ustc RPM-GPG-KEY-EPEL-7	
}

pip_conf(){
	echo  $datetime "INFO 正在配置pip..." | tee -a ${LOGPATH}
	cd /root/
	if [ ! -d .pip ];then
        	mkdir .pip
	else
		rm -r .pip
		mkdir .pip
        fi
	cd .pip
	ln -s ../pip.conf ./
}

yum_packages_install(){
	echo  $datetime "INFO 正在进行yum安装..." | tee -a ${LOGPATH}
	while read line
	do
        	yummass=$(yum -y install ${line})
        	if [[ ${yummass} == *installed* ]]; then
                	echo $datetime "INFO ${line}安装成功" | tee -a ${LOGPATH}
        	fi
        done < ${YUMPATH}

	cd /root/NewInstallScript/ConfigurationFile/sfu/
        sfumass=$(yum -y install sfutils-6.0.3.1001-1.x86_64.rpm)
        if [[ ${sfumass} == *installed* ]]; then
        	echo $datetime "INFO sfutils安装成功" | tee -a ${LOGPATH}
        fi
}

pip_packages_install(){
        echo  $datetime "INFO 正在进行pip安装..." | tee -a ${LOGPATH}
        while read line
        do
                pipmass=$(pip install ${line})
                if [[ ${pipmass} == *already* ]]; then
                        echo $datetime "INFO ${line}安装成功" | tee -a ${LOGPATH}
                fi                
        done < ${PIPPATH}
}

main(){

	if [[ ${input_value} == -a ]];then
		echo '=======所有配置========'	
        	network_scripts
        	dns_scripts
        	kernel_install
        	yum_install
        	pip_conf
        	yum_packages_install
        	pip_packages_install

	elif [[ ${input_value} == -n ]];then
                echo '=======网络配置========'
                network_scripts
                dns_scripts
	
	elif [[ ${input_value} == -y ]];then
                echo '=======yum配置========'
                yum_install
                yum_packages_install

        elif [[ ${input_value} == -p ]];then
                echo '=======pip配置========'
                pip_conf
                pip_packages_install
	else
		echo "错误指令，参考：-h: get help  -a: all thing -n: network & dns -y: install for yum -p: install for pip"
		exit 1
	fi

	read -p 'remo old files [y/n]' ans
	if [[ ${ans} == y ]];then
		rm -r ~/NewInstallScript/
	fi
}

if [[ $1 == -h ]]; then
	echo "-h: get help  -a: all thing -n: network & dns -y: install for yum -p: install for pip"
else
	input_value=$1
	main
fi

echo '已完成所有配置'

exit 0

















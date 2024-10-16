#!/bin/bash

green="\e[32m"
red="\e[31m"
yellow="\e[33m"
reset="\e[0m"

#当前脚本版本
script_version=1.0.2

#最新脚本版本获取
get_latest_script_version(){
    latest_script_version=$(curl -s https://api.github.com/repos/HOLAND336/easy-frp/releases/latest | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')
}

get_latest_script_version


#最新版本获取
get_latest(){
    latest=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep 'html_url": "https://github.com/fatedier/frp/releases/tag' | sed -n 's/.*tag\/v\([0-9.]*\).*/\1/p')
}

get_latest

#当前版本获取
get_version() {
    if [[ -f /etc/frp/version.txt ]]; then
        version="${green}$(cat /etc/frp/version.txt)${reset}"
    else
        version="${red}FRP 未安装${reset}"
    fi
}

get_version












# 菜单主页面
menu() {
    while true; do
        get_version
        echo -e "当前最新版本 FRP: ${green}$latest${reset}"
        echo -e "已安装FRP版本：$version"
        echo -e "FRP安装菜单 ${green}$script_version${reset}"
        echo "1. 安装/更新 FRP"
        echo "2. 开启自启 客户端/服务端"
        echo "3. 关闭自启 客户端/服务端"
        echo "4. 重新启动 客户端/服务端"
        echo "5. FRP 状态检查"
        echo "6. 管理脚本更新"
        echo "7. 卸载 FRP"
        echo "0. 退出"
        
        # 提示用户输入
        read -p "请输入一个0-7之间的数字：" choice_01

        # 根据用户的输入执行相应的操作
        case $choice_01 in
            0) echo "退出"; exit ;;
            1) install ;;
            2) enable ;;
            3) disable ;;
            4) restart ;;
            5) status ;;
            6) script_update ;;
            7) uninstall ;;
            *) echo "请输入0-7之间的数字" ;;
        esac
    done
}


#更新
update() {
    get_latest
    get_version
    echo -e "当前版本为$version"
    echo -e "正在更新为$latest"
    echo "正在下载 frp $latest"
    wget -O /root/frp_${latest}_linux_amd64.tar.gz https://github.com/fatedier/frp/releases/download/v${latest}/frp_${latest}_linux_amd64.tar.gz
    echo "开始安装......."
    mkdir -p /etc/frp/tmp
    tar -zxvf /root/frp_${latest}_linux_amd64.tar.gz -C /etc/frp/tmp/
    mv -f /etc/frp/tmp/frp_${latest}_linux_amd64/frpc /etc/frp/frpc
    mv -f /etc/frp/tmp/frp_${latest}_linux_amd64/frps /etc/frp/frps
    echo $latest > /etc/frp/version.txt
    rm -rf /etc/frp/tmp && rm -rf /root/frp_${latest}_linux_amd64.tar.gz
    echo "安装/更新完成"
    read -n 1 -s -r -p "按任意键继续..."
    get_version
}




#输入frp执行脚本
script_up(){
    sudo mkdir -p /usr/local/bin/
    sudo cp -f /root/frp_install.sh /usr/local/bin/frp
    sudo cp -f /root/frp_install.sh /usr/local/bin/FRP    
    sudo chmod +x /usr/local/bin/frp
    sudo chmod +x /usr/local/bin/FRP
    sudo chmod +x /root/frp_install.sh
    return
}

#脚本更新
script_update(){
    get_latest_script_version
    echo -e "当前最新脚本版本为：${green}$latest_script_version${reset}"
    echo -e "当前脚本版本为：${green}$script_version${reset}"
    while true; do
        echo "是否要更新"
        echo "请输入Y/n"
        read input2
        case $input2 in
            Y|y) break ;;
            N|n) return ;;
            *) echo "请输入Y/n" ;;
        esac
    done
    sudo wget -O /root/frp_install.sh "https://github.com/HOLAND336/easy-frp/releases/download/v${latest_script_version}/frp_install.sh"
    if [[ $? -eq 0 ]]; then
        
        # 更新脚本路径和权限
        script_up
        
        echo "脚本更新成功"
        sleep 1
        # 重新执行最新的脚本
        exec frp
    else
        # 下载失败，保留原脚本
        echo -e "${red}脚本下载失败，请检查网络或GitHub地址！${reset}"
        sudo rm -f /root/frp_install.sh
    fi
    return


}



#安装模块
install() {
    get_latest
    get_version
    echo -e "检测最新版本号为：$latest"

    if [[ "$version" == "$latest" ]]; then
        while true; do
            echo "当前脚本已是最新版本frp：$latest"
            echo "1.覆盖文件（不包括配置）"
            echo "0.取消"
            read -p "请输入一个0-1之间的数字：" choice_02
            case $choice_02 in
                0) menu  ;; #返回主菜单
                1) break  ;; #跳过while循环继续往下执行
                *) echo "请输入0-1之间的数字" ;;
            esac
        done
        update #更新
        return #返回主菜单
        
    elif [[ "$version" != "$latest" ]]; then
        update #更新
        return #返回主菜单

    else
        if [[ -f /etc/frp/frpc && -f /etc/frp/frps && -f /etc/frp/frpc.toml && -f /etc/frp/frps.toml ]]; then #判断是否是全新安装
            echo "正在下载 frp $latest"
            wget -O /root/frp_${latest}_linux_amd64.tar.gz https://github.com/fatedier/frp/releases/download/v${latest}/frp_${latest}_linux_amd64.tar.gz
            echo "开始安装......."
            mkdir -p /root/frp_tmp
            tar -zxvf /root/frp_${latest}_linux_amd64.tar.gz -C /root/frp_tmp
            mkdir -p /etc/frp/
            mv -f /root/frp_tmp/frp_${latest}_linux_amd64/* /etc/frp/
            system_install


            echo "安装完成"
            menu
        else #其他异常情况
            echo "检测到配置或残留文件"
            echo "是否进行覆盖（原配置文件将会丢失）y/n"
            read choice_03
            if [[ "$choice_03" == "y" || "$choice_03" == "Y" ]]; then
                echo "正在下载 frp $latest"
                wget -O /root/frp_${latest}_linux_amd64.tar.gz https://github.com/fatedier/frp/releases/download/v${latest}/frp_${latest}_linux_amd64.tar.gz
                echo "开始安装......."
                mkdir -p /root/frp_tmp
                tar -zxvf /root/frp_${latest}_linux_amd64.tar.gz -C /root/frp_tmp
                mkdir -p /etc/frp/
                mv -f /root/frp_tmp/frp_${latest}_linux_amd64/* /etc/frp/
            else
                echo "取消操作"
            fi
        fi
    fi
}



uninstall() {
    echo -e "${red}是否卸载FRP Y/n${reset}"
    while true; do
        echo -e "Y：确认卸载"
        echo -e "n：取消卸载"
        read input1
        case $input1 in
            Y|y) break;;
            N|n) return;;
            *) echo -e "${red}请输入Y或n${reset}"
        esac
    done
    echo "正在卸载FRP"
    sudo systemctl stop frpc
    sudo systemctl disable frpc
    sudo rm -rf /etc/systemd/system/frpc.service
    sudo systemctl stop frps
    sudo systemctl disable frps
    sudo rm -rf /etc/systemd/system/frps.service
    sudo rm -rf /etc/frp
    sudo rm -rf /usr/local/bin/frp
    sudo rm -rf /usr/local/bin/FRP 
    echo "卸载完成"
    read -n 1 -s -r -p "按任意键继续..."
	echo -e "\n"
    get_version


    return
}

enable() {
    while true; do
        echo "1. 启动客户端"
        echo "2. 启动服务端"
        echo "0. 返回主菜单"
        echo "请选择0-2: "
        read -r choice

        # 检测 systemd 文件是否存在
        if [[ ! -f /etc/systemd/system/frpc.service ]]; then
            system_install_c
        fi
        if [[ ! -f /etc/systemd/system/frps.service ]]; then
            system_install_s
        fi

        case $choice in
            1)
                # 启动客户端
                sudo systemctl enable frpc
                sudo systemctl restart frpc
                sudo systemctl status frpc -l
                sleep 1
                read -n 1 -s -r -p "按任意键继续..."
				echo -e "\n"
                return
                ;;
            2)
                # 启动服务端
                sudo systemctl enable frps
                sudo systemctl restart frps
                sudo systemctl status frps -l
                sleep 1
                read -n 1 -s -r -p "按任意键继续..."
				echo -e "\n"
                return
                ;;
            0)
                # 返回菜单
                return
                ;;
            *)
                echo "请选择1-2之间的数字"
                ;;
        esac
    done
}

disable() {
    while true; do
        echo "1. 关闭客户端"
        echo "2. 关闭服务端"
        echo "0. 返回主菜单"
        echo "请选择0-2: "
        read -r choice

        case $choice in
            1)
                # 关闭客户端
                sudo systemctl disable frpc
                sudo systemctl stop frpc
                sudo systemctl status frpc -l
                sleep 1
                read -n 1 -s -r -p "按任意键继续..."
				echo -e "\n"
                return
                ;;
            2)
                # 关闭服务端
                sudo systemctl disable frps
                sudo systemctl stop frps
                sudo systemctl status frps -l
                sleep 1
                read -n 1 -s -r -p "按任意键继续..."
				echo -e "\n"
                return
                ;;
            0)
                # 返回菜单
                return
                ;;
            *)
                echo "请选择1-2之间的数字"
                ;;
        esac
    done
}

system_install_c() {
    # 定义服务文件路径
    service_file_c="/etc/systemd/system/frpc.service"

    # 服务配置内容
    service_content_c="[Unit]
Description=frpc
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
ExecStart=/etc/frp/frpc -c /etc/frp/frpc.toml

[Install]
WantedBy=multi-user.target"

    echo "$service_content_c" > "$service_file_c"
    read -n 1 -s -r -p "按任意键继续..."
	echo -e "\n"
}

system_install_s() {
    # 定义服务文件路径
    service_file_s="/etc/systemd/system/frps.service"

    # 服务配置内容
    service_content_s="[Unit]
Description=frps
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
ExecStart=/etc/frp/frps -c /etc/frp/frps.toml

[Install]
WantedBy=multi-user.target"

    echo "$service_content_s" > "$service_file_s"
    read -n 1 -s -r -p "按任意键继续..."
	echo -e "\n"
}



restart() {
    while true; do
        echo "输入 1 重启客户端"
        echo "输入 2 重启服务端"
        echo "输入 0 返回主菜单"
        read -e -p "请选择 (1 重启客户端, 2 重启服务端, 0 返回主菜单): " input3
        case $input3 in
            1) restart_c 
               return ;;
            2) restart_s
               return ;;
            0) return ;;
            *) echo -e "请输入数字0-2" ;;
        esac
    done
}



restart_c() {
    clear
    echo "正在重启客户端..."
    sudo systemctl restart frpc
    seperator
    sudo systemctl status frpc
    seperator
    sleep 2
    clear
    return
}



restart_s() {
    clear
    echo "正在重启服务端..."
    sudo systemctl restart frps
    seperator
    sudo systemctl status frps
    seperator
    sleep 2
    clear
    return
}


status() {
    seperator
    echo "客户端状态"
    sudo systemctl status frpc -l
    seperator
    echo -e "\n"
    seperator
    echo "服务端状态"
    sudo systemctl status frps -l
    seperator
    echo -e "\n"
    read -n 1 -s -r -p "按任意键继续..."
	echo -e "\n"
} 


seperator() {
    printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'
}



#第一次自动安装脚本
if [[ ! -f /usr/local/bin/frp || ! -f /usr/local/bin/FRP ]]; then
    echo "检测到第一次使用，正在安装脚本面板..."
    script_up
    echo "面板安装成功！"
    echo -e "后面输入 ${green}frp${reset} 即可进入面板"
    read -n 1 -s -r -p "按任意键继续..."
fi


menu

#!/bin/bash

# 安装 Go
install_go() {
    if command -v go &> /dev/null; then
        echo "Go 已经安装，跳过安装步骤。"
        return
    fi

    echo "正在安装 Go..."
    while true; do
        wget https://go.dev/dl/go1.22.8.linux-amd64.tar.gz
        if [ $? -ne 0 ]; then
            echo "下载失败，请重试。"
            continue
        fi
        sudo tar -C /usr/local -xzf go1.22.8.linux-amd64.tar.gz
        echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc

        if go version; then
            echo "Go 安装成功！"
            break
        else
            echo "Go 安装失败，请重试。"
            rm go1.22.8.linux-amd64.tar.gz
        fi
    done
}

# 安装 Node.js 和 PM2
install_node_pm2() {
    if command -v node &> /dev/null && command -v pm2 &> /dev/null; then
        echo "Node.js 和 PM2 已经安装，跳过安装步骤。"
        return
    fi

    echo "正在安装 Node.js 和 PM2..."
    while true; do
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs

        if node -v && npm -v; then
            echo "Node.js 安装成功！"
            break
        else
            echo "Node.js 安装失败，尝试安装 Node.js 16.x..."
            sudo apt-get purge -y nodejs
            curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    done

    if ! command -v npm &> /dev/null; then
        echo "npm 未安装，正在安装..."
        sudo apt install -y npm
    fi

    if ! command -v pm2 &> /dev/null; then
        while true; do
            sudo npm install pm2 -g
            if pm2 -v; then
                echo "PM2 安装成功！"
                break
            else
                echo "PM2 安装失败，请重试。"
            fi
        done
    else
        echo "PM2 已经安装，跳过安装步骤。"
    fi
}

# 克隆官方仓库
clone_repository() {
    echo "正在克隆官方仓库..."
    git clone https://github.com/masa-finance/masa-oracle.git
    cd masa-oracle || { echo "克隆失败，目录不存在！"; return; }

    echo "安装项目依赖..."
    cd contracts
    npm install
    cd ..
}

# 构建项目
build_project() {
    echo "正在构建项目，请耐心等待..."
    cd masa-oracle || { echo "构建失败，目录不存在！"; return; }
    make build
    echo "构建完成！"
}

# 创建配置文件
create_env_file() {
    echo "创建配置文件..."
    mkdir -p ~/masa-oracle
    cat <<EOL > ~/.env
# Default .env configuration
...
EOL

    cp ~/.env ~/masa-oracle/.env
}

# 修改 Twitter 配置
update_twitter_accounts() {
    read -p "请输入账号:密码: " twitter_accounts
    if [[ ! "$twitter_accounts" =~ ^[^:]+:[^:]+$ ]]; then
        echo "格式错误，请输入账号:密码。"
        return
    fi
    sed -i "s/TWITTER_ACCOUNTS=.*/TWITTER_ACCOUNTS=\"$twitter_accounts\"/" ~/.env
    sed -i "s/TWITTER_ACCOUNTS=.*/TWITTER_ACCOUNTS=\"$twitter_accounts\"/" ~/masa-oracle/.env
}

# 配置交换内存
configure_swap() {
    echo "正在配置交换内存..."
    sudo fallocate -l 12G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
    echo "交换内存配置完成！"
}

# 显示私钥
show_private_key() {
    echo "切换到主目录并显示私钥..."
    cd ~ || exit
    if [[ -f ~/.masa/masa_oracle_key.ecdsa ]]; then
        cat ~/.masa/masa_oracle_key.ecdsa
    else
        echo "私钥文件不存在！"
    fi
}

# 领币质押
stake_tokens() {
    echo "正在进行领币质押..."
    cd ~/masa-oracle || { echo "目录 masa-oracle 不存在！"; return; }
    
    make faucet    
    if [ $? -eq 0 ]; then
        echo "领币成功！"
    else
        echo "领币失败！"
    fi

    make stake
    if [ $? -eq 0 ]; then
        echo "质押成功！"
    else
        echo "质押失败！"
    fi
}

# 主菜单
main_menu() {
    while true; do
        echo "请选择操作:"
        echo "1) 安装 Go"
        echo "2) 安装 Node.js 和 PM2"
        echo "3) 克隆官方仓库"
        echo "4) 构建项目"
        echo "5) 创建配置文件"
        echo "6) 修改 Twitter 配置"
        echo "7) 配置交换内存"
        echo "8) 显示私钥"
        echo "9) 领币质押"
        echo "0) 退出"
        read -p "请输入选项: " option

        case $option in
            1) install_go ;;
            2) install_node_pm2 ;;
            3) clone_repository ;;
            4) build_project ;;
            5) create_env_file ;;
            6) update_twitter_accounts ;;
            7) configure_swap ;;
            8) show_private_key ;;
            9) stake_tokens ;;
            0) echo "退出程序。"; exit 0 ;;
            *) echo "无效选项，请重试。" ;;
        esac
    done
}

# 开始程序
main_menu

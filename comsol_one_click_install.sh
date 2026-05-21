#!/bin/bash
set -e

echo "=========================================="
echo "COMSOL 6.4 完整一条龙安装脚本"
echo "Clone → 下载 → 改名 → 安装"
echo "=========================================="

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# 第一步: 安装基础工具
# ============================================
echo -e "${GREEN}[1/10] 安装基础工具...${NC}"
apt update >/dev/null 2>&1
apt install -y \
    git \
    tree \
    wget \
    curl \
    aria2 \
    screen \
    p7zip-full \
    p7zip-rar \
    rename \
    sed \
    openjdk-11-jdk \
    libxrender1 libxtst6 libxi6 libxrandr2 \
    libxcursor1 libxinerama1 libfreetype6 fontconfig \
    libglu1-mesa libsm6 libice6 libxext6 libx11-6 \
    >/dev/null 2>&1
echo "✓ 基础工具已安装"
echo ""

# ============================================
# 第二步: Clone auto_comsol 仓库
# ============================================
echo -e "${GREEN}[2/10] Clone auto_comsol 仓库...${NC}"
cd /home
if [ ! -d "auto_comsol" ]; then
    git clone https://github.com/dylanyunlon/auto_comsol.git
    echo "✓ 仓库已克隆"
else
    echo "✓ 仓库已存在"
    cd auto_comsol && git pull && cd /home
fi

echo "仓库结构:"
tree -L 2 /home/auto_comsol
echo ""

# ============================================
# 第三步: 启动种子下载
# ============================================
echo -e "${GREEN}[3/10] 启动COMSOL种子下载...${NC}"
MAGNET_LINK="magnet:?xt=urn:btih:7F31928026801DCF2B88A7017DF4E78C8A77F2EE&tr=http%3A%2F%2Fbt2.t-ru.org%2Fann%3Fmagnet&dn=COMSOL%20Multiphysics%206.4%20Build%20293%20Full%20Win-Linux-macOS%20x64%20%5B2025%2Cc"
DOWNLOAD_DIR="/home/comsol_download"

mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# 创建aria2配置
cat > aria2.conf << 'EOF'
continue=true
max-connection-per-server=16
min-split-size=10M
split=16
max-concurrent-downloads=5
enable-dht=true
bt-enable-lpd=true
enable-peer-exchange=true
bt-max-peers=0
seed-ratio=0
bt-seed-unverified=true
max-overall-upload-limit=1K
EOF

# 检查是否已下载
if [ -d "Comsol.Multiphysics.6.4.293-SSQ" ]; then
    TOTAL_SIZE=$(du -sh Comsol.Multiphysics.6.4.293-SSQ | cut -f1)
    echo "✓ COMSOL已下载 (大小: $TOTAL_SIZE)"
    
    # 检查是否完整（大于10GB认为完整）
    SIZE_GB=$(du -s Comsol.Multiphysics.6.4.293-SSQ | awk '{print int($1/1024/1024)}')
    if [ $SIZE_GB -lt 10 ]; then
        echo -e "${YELLOW}文件可能不完整，继续下载...${NC}"
        aria2c --conf-path=aria2.conf --dir="$DOWNLOAD_DIR" --seed-time=0 "$MAGNET_LINK"
    fi
else
    echo "开始下载 (约12GB，可能需要几分钟)..."
    aria2c --conf-path=aria2.conf --dir="$DOWNLOAD_DIR" --seed-time=0 "$MAGNET_LINK"
    echo "✓ 下载完成"
fi
echo ""

# ============================================
# 第四步: 解压破解文件
# ============================================
echo -e "${GREEN}[4/10] 解压破解文件...${NC}"
cd "$DOWNLOAD_DIR/Comsol.Multiphysics.6.4.293-SSQ/_SolidSQUAD_"

# 解压所有.7z文件
for archive in *.7z; do
    if [ -f "$archive" ]; then
        echo "解压: $archive"
        7z x "$archive" -y >/dev/null 2>&1
    fi
done

echo "✓ 破解文件已解压"
echo "当前文件:"
ls -lh
echo ""

# ============================================
# 第五步: 批量替换 SSQ/SolidSQUAD → dylan
# ============================================
echo -e "${GREEN}[5/10] 替换所有 SSQ/SolidSQUAD → dylan...${NC}"
cd "$DOWNLOAD_DIR/Comsol.Multiphysics.6.4.293-SSQ"

echo "替换文件内容..."
# 替换所有文本文件中的内容
find . -type f \( -name "*.lic" -o -name "*.txt" -o -name "*.sh" -o -name "*.bat" -o -name "*.xml" -o -name "*.ini" -o -name "*.dat" \) -exec sed -i \
    -e 's/SSQ/dylan/g' \
    -e 's/SolidSQUAD/dylan/g' \
    -e 's/SOLIDSQUAD/DYLAN/g' \
    -e 's/solidsquad/dylan/g' \
    {} \; 2>/dev/null || true

echo "✓ 文件内容已替换"
echo ""

echo "重命名文件和目录..."
cd "$DOWNLOAD_DIR"

# 重命名目录
if [ -d "Comsol.Multiphysics.6.4.293-SSQ" ]; then
    mv "Comsol.Multiphysics.6.4.293-SSQ" "Comsol.Multiphysics.6.4.293-dylan" 2>/dev/null || true
fi

cd "Comsol.Multiphysics.6.4.293-dylan" 2>/dev/null || cd "Comsol.Multiphysics.6.4.293-SSQ"

# 重命名_SolidSQUAD_目录
if [ -d "_SolidSQUAD_" ]; then
    mv "_SolidSQUAD_" "_dylan_" 2>/dev/null || true
fi

# 递归重命名所有包含SSQ/SolidSQUAD的文件和目录
find . -depth -name "*SSQ*" -o -name "*SolidSQUAD*" -o -name "*solidsquad*" | while read item; do
    newname=$(echo "$item" | sed -e 's/SSQ/dylan/g' -e 's/SolidSQUAD/dylan/g' -e 's/solidsquad/dylan/g')
    if [ "$item" != "$newname" ]; then
        mv "$item" "$newname" 2>/dev/null || true
        echo "  重命名: $(basename $item) → $(basename $newname)"
    fi
done

echo "✓ 文件和目录已重命名"
echo ""

echo "验证替换结果:"
find . -name "*.lic" -exec basename {} \;
echo ""

# ============================================
# 第六步: 挂载ISO
# ============================================
echo -e "${GREEN}[6/10] 挂载ISO文件...${NC}"
ISO_FILE=$(find "$DOWNLOAD_DIR" -name "*.iso" | grep -i comsol | head -1)
MOUNT_DIR="/mnt/comsol_dvd"

if [ -z "$ISO_FILE" ]; then
    echo -e "${RED}错误: 未找到ISO文件${NC}"
    exit 1
fi

echo "ISO: $ISO_FILE"
mkdir -p "$MOUNT_DIR"
umount "$MOUNT_DIR" 2>/dev/null || true
mount -o loop "$ISO_FILE" "$MOUNT_DIR"
echo "✓ ISO已挂载到: $MOUNT_DIR"
echo ""

# ============================================
# 第七步: 准备安装配置
# ============================================
echo -e "${GREEN}[7/10] 准备安装配置...${NC}"
CRACK_DIR="$DOWNLOAD_DIR/Comsol.Multiphysics.6.4.293-dylan/_dylan_"
INSTALL_DIR="/opt/comsol64/comsol64"

# 查找license文件
LICENSE_FILE=$(find "$CRACK_DIR" -name "*.lic" | head -1)
if [ -z "$LICENSE_FILE" ]; then
    echo -e "${RED}错误: 未找到license文件${NC}"
    exit 1
fi

echo "License: $LICENSE_FILE"
echo "安装目录: $INSTALL_DIR"
echo ""

# 设置环境变量
export COMSOL_NUM_NUMA=1
echo "export COMSOL_NUM_NUMA=1"
echo ""

# ============================================
# 第八步: 执行静默安装
# ============================================
echo -e "${GREEN}[8/10] 执行COMSOL静默安装...${NC}"
echo "这可能需要5-15分钟..."

cd "$MOUNT_DIR"

# 尝试静默安装
mkdir -p "$INSTALL_DIR"

echo "尝试静默安装方法1..."
if bash ./setup -silent -DINSTALL_DIR="$INSTALL_DIR" -DLICENSE_FILE="$LICENSE_FILE" 2>&1 | tee /tmp/comsol_install.log | grep -q "Installation completed"; then
    echo "✓ 安装成功 (方法1)"
elif bash ./setup -i silent -DUSER_INSTALL_DIR="$INSTALL_DIR" -DLICENSE_FILE="$LICENSE_FILE" 2>&1 | tee /tmp/comsol_install.log; then
    echo "✓ 安装成功 (方法2)"
else
    echo -e "${YELLOW}静默安装可能失败，检查结果...${NC}"
fi

# 检查安装
if [ -f "$INSTALL_DIR/bin/comsol" ]; then
    echo "✓ COMSOL安装成功"
else
    # 查找实际安装位置
    ACTUAL_BIN=$(find /opt /usr/local -name "comsol" -path "*/bin/comsol" 2>/dev/null | head -1)
    if [ -n "$ACTUAL_BIN" ]; then
        INSTALL_DIR=$(dirname $(dirname "$ACTUAL_BIN"))
        echo "✓ COMSOL安装在: $INSTALL_DIR"
    else
        echo -e "${RED}✗ 安装失败${NC}"
        echo "日志: /tmp/comsol_install.log"
        exit 1
    fi
fi
echo ""

# ============================================
# 第九步: 应用Server Workaround
# ============================================
echo -e "${GREEN}[9/10] 应用Server Workaround...${NC}"
WORKAROUND="/home/auto_comsol/comsol/server_install_workaround/comsol_Server_Workaround.sh"

if [ -f "$WORKAROUND" ]; then
    cp "$WORKAROUND" "$INSTALL_DIR/"
    cd "$INSTALL_DIR"
    chmod +x comsol_Server_Workaround.sh
    
    echo "运行workaround..."
    ./comsol_Server_Workaround.sh 2>&1 | tee /tmp/workaround.log
    echo "✓ Workaround已应用"
else
    echo -e "${YELLOW}未找到workaround脚本，跳过${NC}"
fi
echo ""

# ============================================
# 第十步: 创建启动脚本和环境配置
# ============================================
echo -e "${GREEN}[10/10] 创建启动脚本...${NC}"

# 启动脚本
cat > /usr/local/bin/comsol << EOF
#!/bin/bash
export COMSOL_NUM_NUMA=1
cd $INSTALL_DIR
./bin/comsol multiphysics "\$@"
EOF

cat > /usr/local/bin/comsol-server << EOF
#!/bin/bash
export COMSOL_NUM_NUMA=1
cd $INSTALL_DIR
./bin/comsol server "\$@"
EOF

chmod +x /usr/local/bin/comsol
chmod +x /usr/local/bin/comsol-server

# 环境变量
cat > /etc/profile.d/comsol.sh << EOF
export COMSOL_NUM_NUMA=1
export COMSOL_ROOT=$INSTALL_DIR
export PATH=\$PATH:$INSTALL_DIR/bin
EOF

echo "✓ 启动脚本已创建"
echo ""

# ============================================
# 完成总结
# ============================================
echo "=========================================="
echo -e "${GREEN}🎉 安装完成！${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}📁 文件位置:${NC}"
echo "   下载目录: $DOWNLOAD_DIR"
echo "   安装目录: $INSTALL_DIR"
echo "   ISO挂载: $MOUNT_DIR"
echo "   License: $LICENSE_FILE"
echo ""
echo -e "${BLUE}🔄 替换结果:${NC}"
echo "   SSQ → dylan ✓"
echo "   SolidSQUAD → dylan ✓"
find "$CRACK_DIR" -name "*.lic" -exec basename {} \; | sed 's/^/   /'
echo ""
echo -e "${BLUE}🚀 启动命令:${NC}"
LICENSE_TYPE=$(basename "$LICENSE_FILE" | grep -o "Server\|Multiphysics")
if echo "$LICENSE_TYPE" | grep -qi "server"; then
    echo "   COMSOL Server:"
    echo "   $ comsol-server"
    echo ""
    echo "   首次启动需创建管理员账户"
    echo "   然后访问: http://localhost:2036"
else
    echo "   COMSOL Multiphysics:"
    echo "   $ comsol"
fi
echo ""
echo -e "${BLUE}🧪 测试安装:${NC}"
echo "   $ $INSTALL_DIR/bin/comsol -version"
echo ""
echo -e "${BLUE}📋 日志文件:${NC}"
echo "   安装: /tmp/comsol_install.log"
[ -f "/tmp/workaround.log" ] && echo "   Workaround: /tmp/workaround.log"
echo ""
echo -e "${BLUE}💾 如果需要卸载ISO:${NC}"
echo "   $ umount $MOUNT_DIR"
echo ""
echo "=========================================="
echo -e "${GREEN}Created by TeAM dylan-dylan${NC}"
echo "=========================================="

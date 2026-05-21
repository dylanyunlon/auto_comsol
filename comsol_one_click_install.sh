cat > /home/auto_comsol/comsol_one_click_install.sh << 'SCRIPT_EOF'
#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  COMSOL 6.4 完整一条龙安装脚本"
echo "  Clone → 下载 → 解压 → 重命名 → 安装"
echo "  → License Server → 验证"
echo "=========================================="
echo ""

DOWNLOAD_DIR="/home/comsol_download"
SSQ_DIR="$DOWNLOAD_DIR/Comsol.Multiphysics.6.4.293-SSQ"
DYLAN_DIR="$DOWNLOAD_DIR/Comsol.Multiphysics.6.4.293-dylan"
CRACK_DIR_SSQ="$SSQ_DIR/_SolidSQUAD_"
CRACK_DIR_DYLAN="$DYLAN_DIR/_dylan_"
INSTALL_DIR="/opt/comsol64/comsol64"
MOUNT_DIR="/mnt/comsol_dvd"
LMGRD_LOG="/tmp/lmgrd.log"
INSTALL_LOG="/tmp/comsol_install.log"
MAGNET_LINK="magnet:?xt=urn:btih:7F31928026801DCF2B88A7017DF4E78C8A77F2EE&tr=http%3A%2F%2Fbt2.t-ru.org%2Fann%3Fmagnet&dn=COMSOL%20Multiphysics%206.4%20Build%20293%20Full%20Win-Linux-macOS%20x64%20%5B2025%2Cc"

echo -e "${GREEN}[1/9] 安装基础工具...${NC}"
apt-get update -qq
apt-get install -y \
    git tree wget curl aria2 screen \
    p7zip-full p7zip-rar \
    libgtk-3-0 \
    libxrender1 libxtst6 libxi6 libxrandr2 \
    libxcursor1 libxinerama1 libfreetype6 fontconfig \
    libglu1-mesa libsm6 libice6 libxext6 libx11-6 \
    >/dev/null 2>&1
mkdir -p /usr/tmp/.flexlm
echo "✓ 基础工具已安装"
echo ""

echo -e "${GREEN}[2/9] Clone auto_comsol 仓库...${NC}"
cd /home
if [ ! -d "auto_comsol" ]; then
    git clone https://github.com/dylanyunlon/auto_comsol.git
    echo "✓ 仓库已克隆"
else
    echo "✓ 仓库已存在，更新中..."
    cd auto_comsol && git pull --quiet && cd /home
fi
echo "仓库结构:"
tree -L 2 /home/auto_comsol
echo ""

echo -e "${GREEN}[3/9] 下载 COMSOL 6.4 (约12GB)...${NC}"
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

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

if [ -d "$SSQ_DIR" ] || [ -d "$DYLAN_DIR" ]; then
    SRC_DIR="$SSQ_DIR"
    [ -d "$DYLAN_DIR" ] && SRC_DIR="$DYLAN_DIR"
    SIZE_GB=$(du -s "$SRC_DIR" 2>/dev/null | awk '{print int($1/1024/1024)}')
    if [ "${SIZE_GB:-0}" -ge 10 ]; then
        echo "✓ COMSOL 已下载完整 ($(du -sh "$SRC_DIR" | cut -f1))"
    else
        echo "文件不完整(${SIZE_GB}GB)，继续下载..."
        aria2c --conf-path=aria2.conf --dir="$DOWNLOAD_DIR" --seed-time=0 "$MAGNET_LINK"
    fi
else
    echo "开始下载，可能需要较长时间..."
    aria2c --conf-path=aria2.conf --dir="$DOWNLOAD_DIR" --seed-time=0 "$MAGNET_LINK"
    echo "✓ 下载完成"
fi
echo ""

echo -e "${GREEN}[4/9] 解压破解文件...${NC}"
if [ -d "$CRACK_DIR_SSQ" ]; then
    CURRENT_CRACK="$CRACK_DIR_SSQ"
elif [ -d "$CRACK_DIR_DYLAN" ]; then
    CURRENT_CRACK="$CRACK_DIR_DYLAN"
else
    echo -e "${RED}错误: 找不到破解目录${NC}"; exit 1
fi

cd "$CURRENT_CRACK"
for archive in *.7z; do
    if [ -f "$archive" ]; then
        echo "  解压: $archive"
        7z x "$archive" -y >/dev/null 2>&1 && echo "  ✓ $archive 解压完成"
    fi
done
echo "解压后文件:"; ls -lh
echo ""

echo -e "${GREEN}[5/9] 替换文件内容 SSQ/SolidSQUAD → dylan...${NC}"
if [ -d "$SSQ_DIR" ]; then
    cd "$SSQ_DIR"
    find . -type f \( \
        -name "*.lic" -o -name "*.txt" -o -name "*.sh" \
        -o -name "*.bat" -o -name "*.xml" -o -name "*.ini" \
        -o -name "*.dat" -o -name "*.cfg" \
    \) -exec sed -i \
        -e 's/SSQ/dylan/g' \
        -e 's/SolidSQUAD/dylan/g' \
        -e 's/SOLIDSQUAD/DYLAN/g' \
        -e 's/solidsquad/dylan/g' \
    {} \; 2>/dev/null || true
    echo "  ✓ 文件内容替换完成"
fi
echo ""

echo -e "${GREEN}[6/9] 重命名 SSQ/SolidSQUAD → dylan（文件名/目录名）...${NC}"
cd "$DOWNLOAD_DIR"

if [ -d "Comsol.Multiphysics.6.4.293-SSQ" ] && [ ! -d "Comsol.Multiphysics.6.4.293-dylan" ]; then
    mv "Comsol.Multiphysics.6.4.293-SSQ" "Comsol.Multiphysics.6.4.293-dylan"
    echo "  ✓ 主目录重命名完成"
fi

cd "$DYLAN_DIR"

if [ -d "_SolidSQUAD_" ] && [ ! -d "_dylan_" ]; then
    mv "_SolidSQUAD_" "_dylan_"
    echo "  ✓ 破解目录重命名: _SolidSQUAD_ → _dylan_"
fi

find . -depth \( -name "*SSQ*" -o -name "*SolidSQUAD*" -o -name "*solidsquad*" \) | while read item; do
    newname=$(echo "$item" | sed \
        -e 's/SSQ/dylan/g' \
        -e 's/SolidSQUAD/dylan/g' \
        -e 's/solidsquad/dylan/g')
    if [ "$item" != "$newname" ] && [ -e "$item" ]; then
        mv "$item" "$newname" 2>/dev/null && echo "  重命名: $(basename "$item") → $(basename "$newname")" || true
    fi
done

echo "✓ 重命名完成，当前 .lic 文件:"
find "$DYLAN_DIR" -name "*.lic" | while read f; do echo "  $(basename "$f")"; done
echo ""

echo -e "${GREEN}[7/9] 挂载ISO并执行静默安装...${NC}"
ISO_FILE=$(find "$DOWNLOAD_DIR" -name "*.iso" | grep -i comsol | head -1)
if [ -z "$ISO_FILE" ]; then
    echo -e "${RED}错误: 未找到 ISO 文件${NC}"; exit 1
fi
echo "  ISO: $ISO_FILE"

mkdir -p "$MOUNT_DIR"
umount "$MOUNT_DIR" 2>/dev/null || true
mount -o loop "$ISO_FILE" "$MOUNT_DIR"
echo "  ✓ ISO 已挂载到 $MOUNT_DIR"

LICENSE_FILE=$(find "$CRACK_DIR_DYLAN" -name "*Multiphysics*.lic" | head -1)
[ -z "$LICENSE_FILE" ] && LICENSE_FILE=$(find "$CRACK_DIR_DYLAN" -name "*.lic" | head -1)
if [ -z "$LICENSE_FILE" ]; then
    echo -e "${RED}错误: 未找到 license 文件${NC}"; exit 1
fi
echo "  License: $LICENSE_FILE"

cat > /tmp/comsol_silent.ini << EOF
installdir = $INSTALL_DIR
installmode = install
showgui = 0
quiet = 0
agree = 1
license = $LICENSE_FILE
lictype = mph
comsol = 1
licmanager = 1
licmanager.service = 0
doc = no
applications = no
checkupdate = 0
checknewrelease = 0
linuxlauncher = 1
symlinks = 1
fileassoc = 1
EOF

echo "  开始安装（约10-20分钟）..."
export COMSOL_NUM_NUMA=1
mkdir -p "$INSTALL_DIR"
cd "$MOUNT_DIR"
./setup -s /tmp/comsol_silent.ini 2>&1 | tee "$INSTALL_LOG"
SETUP_EXIT=${PIPESTATUS[0]}

if [ "$SETUP_EXIT" -le 1 ]; then
    echo "✓ COMSOL 安装成功 (exit code: $SETUP_EXIT)"
elif [ "$SETUP_EXIT" -le 2 ]; then
    echo -e "${YELLOW}⚠ 安装完成但有错误 (exit code: $SETUP_EXIT)，继续...${NC}"
else
    echo -e "${RED}✗ 安装失败 (exit: $SETUP_EXIT)，查看: $INSTALL_LOG${NC}"; exit 1
fi

if [ ! -f "$INSTALL_DIR/bin/comsol" ]; then
    echo -e "${RED}✗ $INSTALL_DIR/bin/comsol 不存在${NC}"; exit 1
fi
echo "✓ 验证: $($INSTALL_DIR/bin/comsol -version)"
echo ""

echo -e "${GREEN}[8/9] 应用 Server Workaround...${NC}"
WORKAROUND=$(find /home/auto_comsol -name "COMSOL_Server_Workaround.sh" | head -1)
if [ -n "$WORKAROUND" ]; then
    cp "$WORKAROUND" "$INSTALL_DIR/"
    cd "$INSTALL_DIR"
    chmod +x COMSOL_Server_Workaround.sh
    bash COMSOL_Server_Workaround.sh 2>&1 | tee /tmp/workaround.log
    echo "✓ Workaround 已应用（macOS tar 报错可忽略）"
else
    echo -e "${YELLOW}未找到 workaround 脚本，跳过${NC}"
fi
echo ""

echo -e "${GREEN}[9/9] 配置并启动 License Server...${NC}"
LMGRD="$INSTALL_DIR/license/glnxa64/lmgrd"
LMUTIL="$INSTALL_DIR/license/glnxa64/lmutil"
LMCOMSOL="$INSTALL_DIR/license/glnxa64/LMCOMSOL"
HOSTNAME_VAL=$(hostname)

sed -i '/^SERVER /d; /^DAEMON LMCOMSOL/d' "$LICENSE_FILE"
sed -i "1s|^|SERVER $HOSTNAME_VAL ANY 1718\nDAEMON LMCOMSOL $LMCOMSOL\n\n|" "$LICENSE_FILE"
echo "  ✓ LICENSE 文件 SERVER 行已配置"
head -4 "$LICENSE_FILE"
echo ""

pkill -9 -f lmgrd 2>/dev/null || true
pkill -9 -f LMCOMSOL 2>/dev/null || true
sleep 2

rm -f "$LMGRD_LOG"
nohup "$LMGRD" -c "$LICENSE_FILE" -l "$LMGRD_LOG" -local > /tmp/lmgrd_stdout.log 2>&1 &
echo "  等待 License Server 就绪 (10s)..."
sleep 10

$LMUTIL lmstat -a -c 1718@localhost 2>&1 | grep -E "UP|DOWN|Error|license server" | head -3

OUTPUT=$($INSTALL_DIR/bin/comsol batch -nodesktop -nosplash 2>&1 | head -5)
if echo "$OUTPUT" | grep -q "Input filename is not specified"; then
    echo "  ✓ COMSOL License 获取成功"
fi

cat > /etc/systemd/system/comsol-lmgrd.service << EOF
[Unit]
Description=COMSOL FlexLM License Server
After=network.target

[Service]
Type=forking
Environment=COMSOL_NUM_NUMA=1
ExecStartPre=/bin/mkdir -p /usr/tmp/.flexlm
ExecStart=$LMGRD -c $LICENSE_FILE -l $LMGRD_LOG -local
ExecStop=/usr/bin/pkill -f lmgrd
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable comsol-lmgrd.service 2>/dev/null || true

cat > /usr/local/bin/comsol-batch << EOF
#!/bin/bash
export COMSOL_NUM_NUMA=1
$INSTALL_DIR/bin/comsol batch -nodesktop -nosplash "\$@"
EOF
chmod +x /usr/local/bin/comsol-batch

cat > /etc/profile.d/comsol.sh << EOF
export COMSOL_NUM_NUMA=1
export COMSOL_ROOT=$INSTALL_DIR
export PATH=\$PATH:$INSTALL_DIR/bin
EOF

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 COMSOL 6.4 安装完成！${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}📁 关键路径:${NC}"
echo "   安装目录:  $INSTALL_DIR"
echo "   License:   $LICENSE_FILE"
echo "   LM日志:    $LMGRD_LOG"
echo ""
echo -e "${BLUE}🔄 重命名结果:${NC}"
echo "   Comsol.Multiphysics.6.4.293-SSQ → Comsol.Multiphysics.6.4.293-dylan ✓"
echo "   _SolidSQUAD_ → _dylan_ ✓"
echo "   *.lic SSQ/SolidSQUAD → dylan ✓"
echo ""
echo -e "${BLUE}🔑 License Server:${NC}"
echo "   端口:  1718@localhost"
echo "   自启:  systemctl status comsol-lmgrd"
echo ""
echo -e "${BLUE}🚀 使用方法:${NC}"
echo "   comsol-batch -inputfile model.mph -outputfile result.mph"
echo "   $INSTALL_DIR/bin/comsol -version"
echo ""
echo "=========================================="
echo -e "${GREEN}Created by TeAM dylan-dylan${NC}"
echo "=========================================="
SCRIPT_EOF

chmod +x /home/auto_comsol/comsol_one_click_install.sh
echo "✓ 写入完成"
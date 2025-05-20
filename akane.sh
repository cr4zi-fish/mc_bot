#!/bin/bash

clear

echo "=== Setup môi trường và chạy Minecraft Bot Tester với proxy + theo dõi trạng thái bot ==="

# Kiểm tra Node.js
if ! command -v node &> /dev/null
then
    echo "Node.js chưa được cài đặt. Cài đặt Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Tạo thư mục bot
mkdir -p join_ip_tool
cd join_ip_tool

if [ ! -f package.json ]; then
    npm init -y
fi

npm install mineflayer socks5-https-client

# Ghi file multiBot.js
cat > multiBot.js << 'EOF'
const mineflayer = require('mineflayer');
const SocksProxyAgent = require('socks5-https-client/lib/Agent');
const fs = require('fs');

const serverIP = process.argv[2];
const serverPort = parseInt(process.argv[3]);
const botCount = Math.min(parseInt(process.argv[4]), 1000);
const useProxy = process.argv[5] === 'yes';
const proxyFile = process.argv[6] || 'proxies.txt';
const nameFile = process.argv[7] || null;

let proxies = [];
if (useProxy) {
    try {
        proxies = fs.readFileSync(proxyFile, 'utf-8')
            .split('\n')
            .map(l => l.trim())
            .filter(l => l.length > 0 && !l.startsWith('#'));
    } catch (e) {
        console.error(`Không thể đọc file proxy: ${proxyFile}, bot sẽ kết nối thẳng.`);
    }
}

let nameList = [];
let usingNameList = false;
if (nameFile) {
    try {
        nameList = fs.readFileSync(nameFile, 'utf-8')
            .split('\n')
            .map(n => n.trim())
            .filter(n => n.length > 0 && !n.startsWith('#'));
        usingNameList = nameList.length > 0;
    } catch (e) {
        console.error(`Không thể đọc file tên bot: ${nameFile}`);
    }
}

function getRandomProxy() {
    if (proxies.length === 0) return null;
    const proxy = proxies[Math.floor(Math.random() * proxies.length)];
    const [host, port] = proxy.split(':');
    return { host, port: parseInt(port) };
}

function getBotUsername(index) {
    if (usingNameList && index < nameList.length) {
        return nameList[index];
    }
    return 'b' + Math.random().toString(36).substring(2, 10);
}

function createBot(id) {
    const username = getBotUsername(id);
    const options = {
        host: serverIP,
        port: serverPort,
        username: username,
    };

    if (useProxy) {
        const proxy = getRandomProxy();
        if (proxy) {
            options.agent = new SocksProxyAgent({
                socksHost: proxy.host,
                socksPort: proxy.port,
                socksVersion: 5,
            });
            console.log(`[${username}] dùng proxy ${proxy.host}:${proxy.port}`);
        } else {
            console.log(`[${username}] không tìm thấy proxy, kết nối thẳng.`);
        }
    } else {
        console.log(`[${username}] kết nối trực tiếp.`);
    }

    const bot = mineflayer.createBot(options);

    let connected = false;

    bot.on('login', () => {
        connected = true;
        console.log(`[${username}] đã đăng nhập.`);
    });

    bot.on('kicked', (reason) => {
        console.log(`[${username}] bị kick: ${reason}`);
        retry();
    });

    bot.on('error', (err) => {
        console.log(`[${username}] lỗi: ${err.message}`);
    });

    bot.on('end', () => {
        if (!connected) {
            console.log(`[${username}] ngắt kết nối trước khi login, thử lại sau 1s.`);
            setTimeout(() => createBot(id), 1000);
        } else {
            console.log(`[${username}] đã thoát.`);
            // Không rejoin nếu đã login thành công trước đó
        }
    });

    bot._client.on('keep_alive', () => {});

    function retry() {
        setTimeout(() => createBot(id), 1000);
    }
}

// Khởi tạo bot
for (let i = 0; i < botCount; i++) {
    createBot(i);
}
EOF

# File proxy mẫu
if [ ! -f proxies.txt ]; then
cat > proxies.txt << EOP
# SOCKS5 proxy mỗi dòng dạng ip:port
# Ví dụ:
# 127.0.0.1:1080
# 192.168.1.100:1080
EOP
fi

# File tên bot mẫu
if [ ! -f bot_name.txt ]; then
cat > bot_name.txt << EON
# Tên bot mỗi dòng (tối đa 1000)
# Ví dụ:
# BotOne
# BotTwo
# BotThree
EON
fi

# Nhập thông tin
read -p "Nhập IP server Minecraft: " ip
read -p "Nhập port server (mặc định 25565): " port
port=${port:-25565}

read -p "Nhập số bot muốn join (tối đa 1000): " botcount
botcount=${botcount:-10}
if [ "$botcount" -gt 1000 ]; then botcount=1000; fi

read -p "Bạn có muốn dùng proxy không? (yes/no, mặc định no): " useproxy
useproxy=${useproxy:-no}

proxyfile="proxies.txt"
if [ "$useproxy" = "yes" ]; then
    read -p "Nhập tên file proxy (mặc định proxies.txt): " proxyfile_input
    proxyfile=${proxyfile_input:-proxies.txt}
fi

read -p "Bạn có muốn dùng tên bot từ file bot_name.txt không? (yes/no, mặc định no): " use_names
use_names=${use_names:-no}
namefile=""
if [ "$use_names" = "yes" ]; then
    read -p "Nhập tên file chứa tên bot (mặc định bot_name.txt): " namefile_input
    namefile=${namefile_input:-bot_name.txt}
fi

echo "Khởi động bot... (ấn Ctrl+C để dừng)"

# Vòng lặp bảo vệ tiến trình node.js
while true
do
    node multiBot.js "$ip" "$port" "$botcount" "$useproxy" "$proxyfile" "$namefile"
    echo "multiBot.js đã thoát, thử lại sau 3 giây..."
    sleep 3
done

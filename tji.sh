#!/bin/bash

echo "=== Setup môi trường và chạy Minecraft Bot Tester với tùy chọn Proxy ==="

# Kiểm tra Node.js
if ! command -v node &> /dev/null
then
    echo "Node.js chưa được cài đặt. Cài đặt Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

mkdir -p mc_bot_tester
cd mc_bot_tester

if [ ! -f package.json ]; then
    npm init -y
fi

npm install mineflayer socks5-https-client

cat > multiBot.js << 'EOF'
const mineflayer = require('mineflayer');
const SocksProxyAgent = require('socks5-https-client/lib/Agent');
const fs = require('fs');

const serverIP = process.argv[2];
const serverPort = parseInt(process.argv[3]);
const botCount = Math.min(parseInt(process.argv[4]), 1000);
const useProxy = process.argv[5] === 'yes'; // 'yes' dùng proxy, 'no' không dùng
const proxyFile = process.argv[6] || 'proxies.txt';

let proxies = [];
if(useProxy){
  try {
    proxies = fs.readFileSync(proxyFile, 'utf-8')
      .split('\n')
      .map(l => l.trim())
      .filter(l => l.length > 0);
  } catch (e) {
    console.error(`Không thể đọc file proxy: ${proxyFile}, bot sẽ kết nối thẳng.`);
    proxies = [];
  }
}

function getRandomProxy() {
  if (proxies.length === 0) return null;
  const proxy = proxies[Math.floor(Math.random() * proxies.length)];
  const [host, port] = proxy.split(':');
  return { host, port: parseInt(port) };
}

function createBot(id) {
  const options = {
    host: serverIP,
    port: serverPort,
    username: `TestBot${id}`,
  };

  if(useProxy){
    const proxy = getRandomProxy();
    if(proxy){
      options.agent = new SocksProxyAgent({
        socksHost: proxy.host,
        socksPort: proxy.port,
        socksVersion: 5,
      });
      console.log(`Bot TestBot${id} dùng proxy ${proxy.host}:${proxy.port}`);
    } else {
      console.log(`Bot TestBot${id} không tìm thấy proxy, kết nối thẳng.`);
    }
  } else {
    console.log(`Bot TestBot${id} kết nối trực tiếp không dùng proxy.`);
  }

  const bot = mineflayer.createBot(options);

  bot.on('login', () => {
    console.log(`Bot TestBot${id} đã đăng nhập thành công.`);
  });

  bot.on('kicked', (reason) => {
    console.log(`Bot TestBot${id} bị kick: ${reason}`);
  });

  bot.on('error', (err) => {
    console.log(`Bot TestBot${id} lỗi: ${err.message}`);
  });

  bot.on('end', () => {
    console.log(`Bot TestBot${id} đã ngắt kết nối, sẽ thử kết nối lại sau 0.1s.`);
    setTimeout(() => {
      createBot(id);
    }, 10);
  });

  bot._client.on('keep_alive', () => {});
}

for (let i = 1; i <= botCount; i++) {
  createBot(i);
}
EOF

# Tạo file proxies.txt mẫu nếu chưa có
if [ ! -f proxies.txt ]; then
cat > proxies.txt << EOP
# Đặt proxy SOCKS5 mỗi dòng dạng ip:port, ví dụ:
# 127.0.0.1:1080
# 192.168.1.100:1080
EOP
fi

read -p "Nhập IP server Minecraft: " ip
read -p "Nhập port server (mặc định 25565): " port
port=${port:-25565}

read -p "Nhập số bot muốn join (tối đa 1000): " botcount
if [ -z "$botcount" ]; then botcount=10; fi
if [ "$botcount" -gt 100 ]; then botcount=100; fi

read -p "Bạn có muốn dùng proxy không? (yes/no, mặc định no): " useproxy
useproxy=${useproxy:-no}

proxyfile="proxies.txt"
if [ "$useproxy" = "yes" ]; then
  read -p "Nhập tên file proxy (mặc định proxies.txt): " proxyfile_input
  proxyfile=${proxyfile_input:-proxies.txt}
fi

echo "Đang chạy bot..."
node multiBot.js "$ip" "$port" "$botcount" "$useproxy" "$proxyfile"

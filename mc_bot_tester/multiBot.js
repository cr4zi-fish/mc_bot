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

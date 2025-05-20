const mineflayer = require('mineflayer');
const SocksProxyAgent = require('socks5-https-client/lib/Agent');
const fs = require('fs');

const serverIP = process.argv[2];
const serverPort = parseInt(process.argv[3]);
const botCount = Math.min(parseInt(process.argv[4]), 1000);
const useProxy = process.argv[5] === 'yes';
const proxyFile = process.argv[6] || 'proxies.txt';

let proxies = [];
if (useProxy) {
    try {
        proxies = fs.readFileSync(proxyFile, 'utf-8')
            .split('\n')
            .map(l => l.trim())
            .filter(l => l.length > 0 && !l.startsWith('#'));
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

function getRandomUsername() {
    return 'b' + Math.random().toString(36).substring(2, 10);
}

function createBot(id) {
    const username = getRandomUsername();
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
            console.log(`Bot ${username} dùng proxy ${proxy.host}:${proxy.port}`);
        } else {
            console.log(`Bot ${username} không tìm thấy proxy, kết nối thẳng.`);
        }
    } else {
        console.log(`Bot ${username} kết nối trực tiếp không dùng proxy.`);
    }

    const bot = mineflayer.createBot(options);

    bot.on('login', () => {
        console.log(`Bot ${username} đã đăng nhập thành công.`);
    });

    bot.on('kicked', (reason) => {
        console.log(`Bot ${username} bị kick: ${reason}`);
    });

    bot.on('error', (err) => {
        console.log(`Bot ${username} lỗi: ${err.message}`);
    });

    bot.on('end', () => {
        console.log(`Bot ${username} đã ngắt kết nối, sẽ thử lại sau 0.01 giây.`);
        setTimeout(() => {
            createBot(id);
        }, 10); // 0.01 giây = 10ms
    });

    bot._client.on('keep_alive', () => {});
}

for (let i = 1; i <= botCount; i++) {
    createBot(i);
}

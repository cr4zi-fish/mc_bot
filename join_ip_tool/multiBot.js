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

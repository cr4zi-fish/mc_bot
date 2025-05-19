
const express = require('express');
const multer = require('multer');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const port = 3000;

app.use(express.static('public'));

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    cb(null, 'proxies.txt');
  }
});

const upload = multer({ storage });

app.post('/run', upload.single('proxyFile'), (req, res) => {
  const ip = req.body.ip;
  const portNum = req.body.port;
  const count = req.body.count || 10;
  const useProxy = req.body.useProxy ? 'yes' : 'no';
  const proxyFile = req.file ? req.file.path : '';

  const command = `node multiBot.js ${ip} ${portNum} ${count} ${useProxy} ${proxyFile}`;

  exec(command, { cwd: __dirname }, (error, stdout, stderr) => {
    if (error) {
      res.send(`Lỗi: ${error.message}`);
      return;
    }
    if (stderr) {
      res.send(`Stderr: ${stderr}`);
      return;
    }
    res.send(stdout);
  });
});

app.listen(port, () => {
  console.log(`Web GUI chạy tại http://localhost:${port}`);
});

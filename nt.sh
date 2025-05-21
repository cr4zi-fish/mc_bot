#!/bin/bash

echo "Nhập IP và PORT (ví dụ: 127.0.0.1:25565):"
read IP_PORT

echo "Nhập protocol version (ví dụ: 760):"
read PROTOCOL

echo "Chọn METHOD từ danh sách sau:"
echo "--------------------------------------"
echo "bigpacket"
echo "botjoiner"
echo "doublejoin"
echo "emptypacket"
echo "gayspam"
echo "handshake"
echo "invaliddata"
echo "invalidspoof"
echo "invalidnames"
echo "spoof"
echo "join"
echo "legacyping"
echo "legitnamejoin"
echo "localhost"
echo "pingjoin"
echo "longhost"
echo "longnames"
echo "nullping"
echo "ping"
echo "query"
echo "randompacket"
echo "bighandshake"
echo "unexpectedpacket"
echo "memory"
echo "test"
echo "--------------------------------------"
echo "Nhập tên METHOD:"
read METHOD

echo "Nhập thời gian chạy (tính bằng giây):"
read SECONDS

echo "Nhập CPS (số lần tấn công trong 1s):"
read CPS

# Chạy bot
java -jar MCBOT.jar $IP_PORT $PROTOCOL $METHOD $SECONDS $CPS

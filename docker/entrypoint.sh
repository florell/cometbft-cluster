#!/bin/sh

# Из имени pod’а (например, tendermint-2) извлекаем номер
NODE_NUM=$(echo "$POD_NAME" | grep -o '[0-9]*')
NODE_DIR="/mnt/config/node$NODE_NUM"

if [ ! -f "$NODE_DIR/config/genesis.json" ]; then
  echo "❌ Missing $NODE_DIR/config/genesis.json"
  exit 1
fi

# Запускаем Tendermint с правильным конфигом
exec tendermint node --home "$NODE_DIR"

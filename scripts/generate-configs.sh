#!/bin/bash
set -e

NUM_NODES=4
CONFIG_DIR=./config
IMAGE=tendermint/tendermint:latest

rm -rf "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

NODE_IDS=()

# 1. Генерация конфигов и сбор node_id
for i in $(seq 0 $((NUM_NODES - 1))); do
  NODE_PATH="$CONFIG_DIR/node$i"
  mkdir -p "$NODE_PATH"
  chmod -R 777 config/node$i

  docker run --rm -v "$(pwd)/$NODE_PATH:/tendermint" $IMAGE init --home /tendermint
  NODE_ID=$(docker run --rm -v "$(pwd)/$NODE_PATH:/tendermint" $IMAGE show-node-id --home /tendermint)
  NODE_IDS+=("$NODE_ID")
done

# 2. Копирование genesis.json
cp "$CONFIG_DIR/node0/config/genesis.json" genesis_base.json
for i in $(seq 0 $((NUM_NODES - 1))); do
  cp genesis_base.json "$CONFIG_DIR/node$i/config/genesis.json"
done

# 3. Прописываем persistent_peers
for i in $(seq 0 $((NUM_NODES - 1))); do
  PEERS=()
  for j in $(seq 0 $((NUM_NODES - 1))); do
    if [[ "$i" -ne "$j" ]]; then
      PEERS+=("${NODE_IDS[$j]}@tendermint-$j.tendermint.default.svc.cluster.local:26656")
    fi
  done
  PEERS_STR=$(IFS=, ; echo "${PEERS[*]}")

  CONFIG_TOML="$CONFIG_DIR/node$i/config/config.toml"
  sed -i.bak "s|^persistent_peers = .*|persistent_peers = \"$PEERS_STR\"|" "$CONFIG_TOML"
  sed -i.bak "s|^allow_duplicate_ip = .*|allow_duplicate_ip = true|" "$CONFIG_TOML"
  # для возможности скрейпинга метрик
  sed -i.bak "s/^prometheus *=.*/prometheus = true/" "$CONFIG_TOML"
  sed -i.bak "s|^prometheus_listen_addr *=.*|prometheus_listen_addr = \":26660\"|" "$CONFIG_TOML"

done

echo "✅ Конфиги с persistent_peers готовы в $CONFIG_DIR/"

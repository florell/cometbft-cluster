#!/bin/bash
set -e

NUM_NODES=4
CONFIG_DIR=./config
IMAGE=cometbft/cometbft:v0.37.15

rm -rf "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

NODE_IDS=()

# генерация конфигов и сбор node_id
for i in $(seq 0 $((NUM_NODES - 1))); do
  NODE_PATH="$CONFIG_DIR/node$i"
  mkdir -p "$NODE_PATH"
  chmod -R 777 config/node$i

  docker run --rm -v "$(pwd)/$NODE_PATH:/cometbft" $IMAGE init --home /cometbft
  NODE_ID=$(docker run --rm -v "$(pwd)/$NODE_PATH:/cometbft" $IMAGE show-node-id --home /cometbft)
  NODE_IDS+=("$NODE_ID")
done

sudo chown -R $(id -u):$(id -g) ./config
chmod -R 777 ./config

# копирование genesis.json по всем нодам
cp "$CONFIG_DIR/node0/config/genesis.json" genesis_base.json
for i in $(seq 0 $((NUM_NODES - 1))); do
  cp genesis_base.json "$CONFIG_DIR/node$i/config/genesis.json"
done

# прописываем persistent_peers для связи между узлами
# связь работает на сетевом уровне, p2p
for i in $(seq 0 $((NUM_NODES - 1))); do
  PEERS=()
  for j in $(seq 0 $((NUM_NODES - 1))); do
    if [[ "$i" -ne "$j" ]]; then
      PEERS+=("${NODE_IDS[$j]}@cometbft-$j.cometbft.default.svc.cluster.local:26656")
    fi
  done
  PEERS_STR=$(IFS=, ; echo "${PEERS[*]}")

  CONFIG_TOML="$CONFIG_DIR/node$i/config/config.toml"
  sed -i.bak "s|^persistent_peers = .*|persistent_peers = \"$PEERS_STR\"|" "$CONFIG_TOML"
  sed -i.bak "s|^allow_duplicate_ip = .*|allow_duplicate_ip = true|" "$CONFIG_TOML"
  # для возможности скрейпинга метрик
  sed -i.bak "s/^prometheus *=.*/prometheus = true/" "$CONFIG_TOML"
  sed -i.bak "s|^prometheus_listen_addr *=.*|prometheus_listen_addr = \":26660\"|" "$CONFIG_TOML"
  # чтобы cometbft на каждой ноде знал, куда подключаться к abci приложению внутри пода
  sed -i.bak "s|^proxy_app = .*|proxy_app = \"tcp://0.0.0.0:26658\"|" "$CONFIG_TOML"
  # grpc эндпоинт
  sed -i.bak "s|^grpc_laddr *=.*|grpc_laddr = \"tcp://0.0.0.0:9090\"|" "$CONFIG_TOML"
done

echo "конфиги в $CONFIG_DIR/"

import http.client
import json
import threading
import time

NODES = 4                      # количество нод
TXS = 100                      # транзакций
THREADS = 10                   # потоков

HOST = "127.0.0.1"
PORT = 57546
PATH = "/broadcast_tx_commit?node={}"

def send_tx(i):
    node = i % NODES
    path = PATH.format(node)
    tx_dict = {
        "action": "PUBLISH_CONFIG",
        "data": {
            "key": f"bench_{i}",
            "value": str(time.time())
        }
    }
    json_str = json.dumps(tx_dict, separators=(',', ':'))
    tx_param = 'tx="{}"'.format(json_str.replace('"', '\\"'))
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "*/*"
    }
    try:
        conn = http.client.HTTPConnection(HOST, PORT, timeout=10)
        conn.request("POST", path, body=tx_param, headers=headers)
        resp = conn.getresponse()
        data = resp.read().decode()
        if resp.status == 200:
            print(f"[{i}] success: node={node}")
        else:
            print(f"[{i}] failed: node={node} {resp.status} {data}")
        conn.close()
    except Exception as e:
        print(f"[{i}] exception: node={node} {e}")

def worker(start, count):
    for i in range(start, start + count):
        send_tx(i)

def benchmark():
    print(f"отправляем {TXS} транзакций ({THREADS} потоков) через http.client…")
    t0 = time.time()
    threads = []
    txs_per_thread = TXS // THREADS
    for t in range(THREADS):
        s = t * txs_per_thread
        count = txs_per_thread if t != THREADS - 1 else TXS - s  # последний поток добьёт остаток
        th = threading.Thread(target=worker, args=(s, count))
        threads.append(th)
        th.start()
    for th in threads:
        th.join()
    t1 = time.time()
    print(f"\Estimated time: {t1-t0:.2f} sec, TPS: {TXS/(t1-t0):.2f}")

if __name__ == "__main__":
    benchmark()

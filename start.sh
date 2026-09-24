#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
WORKER_SSH="${WORKER_SSH:-sean@192.168.177.12}"

echo "============================================================"
echo " Starting GLM-5.3-Flash NVFP4 + DFlash2 TP=2 Cluster"
echo " Head   : ai (192.168.177.11) rank 0"
echo " Worker : ai2 (192.168.177.12) rank 1"
echo " RoCE   : rocep1s0f0 + roceP2p1s0f0 (dual HCA merging enabled)"
echo "============================================================"

echo "[1/4] Stopping any existing vllm_glm53 containers..."
docker rm -f vllm_glm53 >/dev/null 2>&1 || true
ssh -T -o BatchMode=yes "$WORKER_SSH" "docker rm -f vllm_glm53 >/dev/null 2>&1 || true"

echo "[2/4] Launching worker (Rank 1) on ${WORKER_SSH}..."
ssh -T -o BatchMode=yes "$WORKER_SSH" "$SCRIPT_DIR/launch-glm53-vllm-tp2-dflash2.sh 1"

echo "[3/4] Waiting 25s for worker initialization..."
for i in $(seq 25 -1 1); do
    printf "\rWaiting %2d seconds for worker to set up distributed group... " "$i"
    sleep 1
done
printf "\rWorker ready!                                              \n"

echo "[4/4] Launching head (Rank 0) on this node..."
"$SCRIPT_DIR/launch-glm53-vllm-tp2-dflash2.sh" 0

echo "============================================================"
echo " Containers up! Streaming head logs live (Ctrl+C to detach)"
echo "============================================================"
exec docker logs -f vllm_glm53

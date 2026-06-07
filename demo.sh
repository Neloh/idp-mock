#!/bin/bash
# demo.sh — Run this to record a GIF using a tool like `terminalizer` or `asciinema`
#
# To record:
#   asciinema rec demo.cast
#   ./demo.sh
#   (stop recording)
#   agg demo.cast demo.gif

set -e
cd "$(dirname "$0")"

# Clean previous runs
rm -rf requests/ infrastructure/

echo ""
echo "=== IDP DEMO — Internal Developer Platform ==="
echo "    Submit a spec > Validate > Approve > Provision"
echo "================================================"
echo ""
sleep 1

echo "[Step 1] Engineer submits a hosting request"
echo "  Command: python platform_cli.py submit --spec examples/trade-service.yaml"
echo ""
sleep 1

python platform_cli.py submit --spec examples/trade-service.yaml
echo ""
sleep 2

# Get the request ID from the saved file
REQ_ID=$(ls requests/ | head -1 | sed 's/.json//')

echo "[Step 2] Platform provisions the infrastructure"
echo "  Command: python provisioner.py --request-id $REQ_ID"
echo ""
sleep 1

python provisioner.py --request-id "$REQ_ID"
echo ""
sleep 2

echo "[Step 3] Verify final state"
echo ""
cat infrastructure/"$REQ_ID".json | python -m json.tool
echo ""
sleep 1

echo "================================================"
echo "  DONE — Service is deployed and ready."
echo "================================================"

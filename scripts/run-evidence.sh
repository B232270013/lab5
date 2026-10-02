#!/usr/bin/env bash
# Capture real PASS, intentional FAIL, and server-DOWN evidence.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/node_modules/.bin:$PATH"
command -v node >/dev/null
command -v newman >/dev/null
command -v curl >/dev/null
mkdir -p results
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/lab05-evidence.XXXXXX")
server_pid=''
cleanup() {
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$work_dir"
}
trap cleanup EXIT
# Never stop an unrelated process already listening on this port.
node -e 'const n=require("net");const s=n.createServer();s.once("error",()=>{console.error("Port 3000 is busy. Stop your existing API before npm run verify.");process.exit(1)});s.listen(3000,()=>s.close());'
node server.js >results/server.txt 2>&1 &
server_pid=$!
ready=0
for attempt in {1..50}; do
  if curl --silent --fail http://localhost:3000/registrations >/dev/null; then ready=1; break; fi
  if ! kill -0 "$server_pid" 2>/dev/null; then cat results/server.txt; exit 1; fi
  sleep 0.1
done
if [[ "$ready" -ne 1 ]]; then echo 'Server failed to start'; exit 1; fi
run_case() {
  local mode=$1 collection=$2 expected=$3
  local run_exit
  set +e
  newman run "$collection" --color off --timeout-request 2000 \
    --reporters cli,json --reporter-json-export "$work_dir/$mode.json" \
    2>&1 | tee "results/newman-$mode.txt"
  run_exit=${PIPESTATUS[0]}
  set -e
  printf '\nexit=%s\n' "$run_exit" | tee -a "results/newman-$mode.txt"
  node - "$mode" "$run_exit" "$work_dir/$mode.json" <<'JS'
const fs = require('fs');
const [mode, code, file] = process.argv.slice(2);
const report = JSON.parse(fs.readFileSync(file, 'utf8'));
const path = 'results/summary.json';
const summary = fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, 'utf8')) : {};
summary[mode] = {exitCode: Number(code), stats: report.run.stats};
fs.writeFileSync(path, JSON.stringify(summary, null, 2) + '\n');
JS
  if [[ "$run_exit" -ne "$expected" ]]; then echo "Unexpected $mode exit=$run_exit (expected $expected)"; exit 1; fi
}
rm -f results/summary.json
run_case pass lab05-collection.json 0
run_case fail lab05-collection-fail.json 1
kill "$server_pid"
wait "$server_pid" 2>/dev/null || true
server_pid=''
run_case down lab05-collection.json 1
if ! rg -q ECONNREFUSED results/newman-down.txt 2>/dev/null; then
  # grep is a portability fallback when ripgrep is not installed.
  grep -q ECONNREFUSED results/newman-down.txt
fi
node - <<'JS'
const fs = require('fs');
const s = JSON.parse(fs.readFileSync('results/summary.json', 'utf8'));
if (s.pass.stats.assertions.failed !== 0 || s.pass.stats.assertions.total !== 72)
  throw new Error('PASS assertion count mismatch');
if (s.fail.stats.assertions.failed !== 1)
  throw new Error('Intentional FAIL must contain exactly one failed assertion');
console.log('Verified: PASS exit=0, FAIL exit=1, DOWN exit=1; 72 assertions in PASS.');
JS

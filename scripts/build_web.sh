#!/usr/bin/env bash
# Builds the web app with everything bundled locally (no CDN) and generates the offline service
# worker. Deploy afterwards with: npx vercel@latest deploy build/web --prod
set -euo pipefail
cd "$(dirname "$0")/.."

flutter build web --release --no-web-resources-cdn
node scripts/gen_sw.mjs build/web

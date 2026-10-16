#!/usr/bin/env bash
# Builds the web app with everything bundled locally (no CDN) and generates the offline service
# worker. Hosting (Netlify) runs this on every push to main; see netlify.toml.
set -euo pipefail
cd "$(dirname "$0")/.."

# .env is also compiled in, because some hosts (Netlify) don't serve the assets/.env dot-file.
if ! grep -qE '^POWERSYNC_URL=.+' .env; then
  echo "WARNING: POWERSYNC_URL is empty in .env; the app will run 'Local only' without sync." >&2
fi

flutter build web --release --no-web-resources-cdn --dart-define-from-file=.env
node scripts/gen_sw.mjs build/web

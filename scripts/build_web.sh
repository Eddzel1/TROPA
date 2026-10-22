#!/usr/bin/env bash
# Builds the web app with everything bundled locally (no CDN) and generates the offline service
# worker. Hosting (Netlify) runs this on every push to main; see netlify.toml.
set -euo pipefail
cd "$(dirname "$0")/.."

# .env is also compiled in, because some hosts (Netlify) don't serve the assets/.env dot-file.
if ! grep -qE '^POWERSYNC_URL=.+' .env; then
  echo "WARNING: POWERSYNC_URL is empty in .env; the app will run 'Local only' without sync." >&2
fi

# Build number = commit count, so each deploy shows a new one on the login page. Netlify may clone
# shallowly, which would undercount, so fetch the full history first when needed.
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
  git fetch --unshallow --quiet || true
fi
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo 1)

flutter build web --release --no-web-resources-cdn --dart-define-from-file=.env \
  --build-number="$BUILD_NUMBER"
node scripts/gen_sw.mjs build/web

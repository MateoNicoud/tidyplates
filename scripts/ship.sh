#!/usr/bin/env bash
# Checks the changed files, copies the addons into the client, and says when /reload is worth asking for.
# Run it before every "please /reload": a /reload without a deploy tests the old code.
set -eu
cd "$(dirname "$0")/.."
scripts/check.sh
scripts/deploy-forever.sh
echo "ship: deployed $(git rev-parse --short HEAD) (+ uncommitted changes): /reload now, with scripts/watch-errors.sh armed"

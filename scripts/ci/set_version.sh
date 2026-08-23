#!/usr/bin/env bash
# [whisker] Single-source version setter.
# Usage: scripts/ci/set_version.sh v1.2.3
# Updates config/app.yml (backend source of truth) and package.json.
set -euo pipefail

V="${1:?usage: set_version.sh vX.Y.Z}"
V="${V#v}"

cd "$(git rev-parse --show-toplevel)"

sed -i.bak -E "s/version: '[^']+'/version: '${V}'/" config/app.yml
rm -f config/app.yml.bak

node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.version = '${V}';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

echo "version set to ${V}"

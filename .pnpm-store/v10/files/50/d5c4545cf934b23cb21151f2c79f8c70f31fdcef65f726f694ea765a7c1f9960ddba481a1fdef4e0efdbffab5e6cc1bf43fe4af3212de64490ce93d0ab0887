#!/bin/sh

export PATH=/usr/local/bin:$PATH

# Enter this script's folder
cd "${0%/*}"

now=$(date +'%d.%m.%Y')
echo "================================================" | tee /dev/stderr
echo "= Starting metadata update at $now"               | tee /dev/stderr
echo "================================================" | tee /dev/stderr

npm run metadata:update:job

# Older way through submitting a pull request to github
# npm run metadata:update:pull-request

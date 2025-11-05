#/bin/bash!

VERSION=$(cat package.json | jq -r .version)

echo "FROM chatwoot/chatwoot:v${VERSION}-ce" > Dockerfile

for i in `git diff master HEAD --name-only`; do 
    echo "COPY /$i /app/$i" >> Dockerfile;
done
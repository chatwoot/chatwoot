# Build image for production

## Build from Apple silicon chips
```
docker buildx create --use
docker buildx build --platform linux/amd64 -t omnipurchase:latest -f ./docker/Dockerfile . --load
docker tag omnipurchase:latest registry.digitalocean.com/nexmeter-registry/omnipurchase:latest
docker push registry.digitalocean.com/nexmeter-registry/omnipurchase:latest 
```

## Build from Windows/Linux
```
docker build -t omnipurchase:latest -f ./docker/Dockerfile .
docker tag omnipurchase:latest registry.digitalocean.com/nexmeter-registry/omnipurchase:latest
docker push registry.digitalocean.com/nexmeter-registry/omnipurchase:latest
```

## How to sync to a later chatwoot checkpoint
In the root dir, run (eg to v4.0.4)
```
git subtree pull --prefix=omni-purchase/omnipurchase-web https://github.com/chatwoot/chatwoot.git refs/tags/v4.0.4 --squash
```

## Testing
Since web chat is related to SDK loading in the browser, the cache might display an old version. Please use incognito mode to load the latest JS SDK to ensure proper testing.
# Test12 change to trigger CD workflow

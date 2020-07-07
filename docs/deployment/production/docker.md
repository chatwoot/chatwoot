---
path: "/docs/deployment/deploy-chatwoot-with-docker"
title: "Docker Chatwoot Production deployment guide"
---

### Deploying with docker

We publish our base images to docker hub. Build your web/worker images from these base images

### Web

```
FROM chatwoot/chatwoot:latest
RUN chmod +x docker/entrypoints/rails.sh
ENTRYPOINT [\"docker/entrypoints/rails.sh\"]
CMD bundle exec bundle exec rails s -b 0.0.0.0 -p 3000"
```

### worker

```
FROM chatwoot/chatwoot:latest
RUN chmod +x docker/entrypoints/rails.sh
ENTRYPOINT [\"docker/entrypoints/rails.sh\"]
CMD bundle exec sidekiq -C config/sidekiq.yml"
```

The app servers will available on port `3000`. Ensure the images are connected to the same database and Redis servers. Provide the configuration for these services via environment variables.

### Upgrading

Update the images using the latest image from chatwoot.  Run the `rails db:migrate` option after accessing console from one of the containers running latest image.

---
path: "/docs/installation-guide-docker"
title: "Docker Setup and Debugging Guide"
---

# Docker Setup and Debugging Guide

## development environment

After cloning the repo and installing docker on your machine, run the following command from the root directory of the project.

```
docker-compose build
```

After building the image or after destroying the stack you would have to reset the database using following command

```
docker-compose run rails bundle exec rails db:reset
```

### Running the app

```
docker-compose run --service-port rails
```

* Access the rails app frontend by visiting `http://0.0.0.0:3000/`
* Access Mailhog inbox by visiting `http://0.0.0.0:8025/` (You will receive all emails going out of the application here)

you can also use the below command instead to run the app and see the full logs.

```
docker-compose up
```

### Destroying the complete composer stack

```
docker-compose down
```

### Running rspec tests

For running the complete rspec tests

```
docker-compose run rails bundle exec rspec
```

For running specific test:

```
docker-compose run rails bundle exec rspec spec/<path-to-file>:<line-number>
```

## production environment

Sometimes you might want to debug the production build locally. You would first need to set `SECRET_KEY_BASE` environment variable in your .env.example file and then run the below commands:

```
docker-compose -f docker-compose.production.yaml build
docker-compose -f docker-compose.production.yaml up
```
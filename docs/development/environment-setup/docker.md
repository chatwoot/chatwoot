---
path: "/docs/installation-guide-docker"
title: "Docker Setup and Debugging Guide"
---

# Docker Setup and Debugging Guide

## development environment

```
docker-compose build
```

After building the image or each time after destroying the stack you would have to create and migrate the database before you can start the rails server or run rspec tests. 

```
docker-compose run rails bundle exec rails db:create db:migrate db:seed
```

### Running the rails app in debug mode (pry and byebug works)

```
docker-compose run --service-port rails
```

* Access the rails app frontend by visiting `http://0.0.0.0:3000/` (You can access the website over http for debugging using pry and Byebug here)

* Access Mailhog inbox by visiting `http://0.0.0.0:8025/` (You will receive all emails going out of the application here)

### Running the complete stack in non-debug mode 

```
docker-compose up
```

* Access the rails app frontend by visiting `http://0.0.0.0:3000/` (This is web only, you cannot debug using docker-compose up)
* Access Mailhog inbox by visiting `http://0.0.0.0:8025/` (You will receive all emails going out of the application here)

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

```
docker-compose -f docker-compose.production.yaml build
```

If you want to test the production build locally you would first need to set `SECRET_KEY_BASE` environment variable in your .env.example file and then run the below command:

```
docker-compose -f docker-compose.production.yaml up
```
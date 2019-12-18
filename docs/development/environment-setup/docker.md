---
path: "/docs/installation-guide-docker"
title: "Docker Setup and Debugging Guide"
---

# Building the Image

## development environment

```
docker-compose build
```

## test environment

```
docker-compose -f docker-compose.test.yaml build
```

## production environment

```
docker-compose -f docker-compose.production.yaml build
```

# Running the Application

## development environment

Before you run the below command please build the development image following the instructions above.

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

### Removing the complete stack

```
docker-compose down
```


## test environment

Before you run the below command please build the test image following the instructions above.

```
docker-compose -f docker-compose.test.yaml run --service-port rspec
```

To run custom tests you can:

```
docker-compose -f docker-compose.test.yaml run --service-port rspec bundle exec rspec <path-to-spec-file>
```

## production environment

Before you run the below command please build the production image following the instructions above.

Then you can tag this image:
```
docker tag chatwoot:latest chatwoot/chatwoot:latest
```

And then push the image to docker hub

```
docker push
```

If you want to test locally how production works you need to set `SECRET_KEY_BASE` environment variable in your .env.example file and then run the below command:

```
docker-compose run --service-port rails
```

You will be able to access the rails app by visiting `http://0.0.0.0:3000/`
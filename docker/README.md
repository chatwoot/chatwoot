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

* Access the rails app frontend by visiting `http://0.0.0.0:3000/`
* Access Mailhog inbox by visiting `http://0.0.0.0:8025/`

### Running the complete stack in non-debug mode 

```
docker-compose up
```

### Removing the complete stack

```
docker-compose down
```


## test environment

Before you run the below command please build the test image following the instructions above.

```
docker-compose -f docker-compose.test.yaml run --service-port rspec
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
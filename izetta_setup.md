# iZetta Setup

Running Locally

## Setup Docker run

### Build The Images

```shell
# build base image first
docker compose build base

# build the server and worker
docker compose build
```

### Prepare DB

```shell
docker-compose run --rm rails bundle exec rails db:chatwoot_prepare
```

### Run

```shell
docker-compose up
```

### Credentials

```hash
url: http://localhost:3000
user_name: john@acme.inc
password: Password1!
```

### Stop app

```shell
docker-compose down
```

## Test widget

build sdk:

```shell
docker-compose run --rm rails sh -c 'BUILD_MODE=library bundle exec vite build'
```

```
visit: http://localhost:3000/widget_tests
```

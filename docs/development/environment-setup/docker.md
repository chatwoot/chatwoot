---
path: "/docs/installation-guide-docker"
title: "Docker Setup and Debugging Guide"
---

### Development environment

After cloning the repo and installing docker on your machine, run the following command from the root directory of the project.

```bash
cp .env.example .env
```

Make changes to the `.env` file as required. [Optional]

```bash
docker-compose build
```

After building the image or after destroying the stack you would have to reset the database using following command

```bash
docker-compose run --rm rails bundle exec rails db:reset
```

### Running the app

```bash
docker-compose run --rm --service-port rails
```

open another terminal and also run below command to run sidekiq in a separate service

```
docker-compose run --rm rails bundle exec sidekiq
```

* Access the rails app frontend by visiting `http://0.0.0.0:3000/`
* Access Mailhog inbox by visiting `http://0.0.0.0:8025/` (You will receive all emails going out of the application here)
* Access Sidekiq Web UI by visiting `http://0.0.0.0:3000/sidekiq` (You need to login with administrator account to access sidekiq)

you can also use the below command instead to run the app and see the full logs.

```bash
docker-compose up
```

### Destroying the complete composer stack

```bash
docker-compose down
```

### Running rspec tests

For running the complete rspec tests

```bash
docker-compose run --rm rails bundle exec rspec
```

For running specific test:

```bash
docker-compose run --rm rails bundle exec rspec spec/<path-to-file>:<line-number>
```

## production environment

Sometimes you might want to debug the production build locally. You would first need to set `SECRET_KEY_BASE` environment variable in your .env.example file and then run the below commands:

```bash
docker-compose -f docker-compose.production.yaml build
docker-compose -f docker-compose.production.yaml up
```

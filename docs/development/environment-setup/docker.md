---
path: "/docs/installation-guide-docker"
title: "Docker Setup"
---

### Pre-requisites
Before proceeding, make sure you have the latest version of `docker` and `docker-compose` installed.

As of now[at the time of writing this doc], we recommend 

    ```bash
    $ docker --version
    Docker version 19.03.3, build a872fc2f86
    $ docker-compose --version
    docker-compose version 1.25.3, build d4d1b42b
    ```

## Development environment

1. Clone the repository.

    ```bash
    $ git clone https://github.com/chatwoot/chatwoot.git
    ```

2. Make a copy of the example environment file and modify as required [optional].

    ```bash
    $ cp .env.example .env
    ```

    If you want to set the password for redis when you run docker-compose, set any string value to the environment variable `REDIS_PASSWORD` in the `.env` file.
    This will secure the redis running inside docker-compose with the given password. 
    Also this will be automatically picked up by the app server and sidekiq, to authenticate while making connections to redis server.

3. Build the images.

    ```bash
    $ docker-compose build
    ```

4. After building the image or after destroying the stack you would have to reset the database using the following command.

    ```bash
    $ docker-compose run --rm rails bundle exec rails db:reset
    ```

5. To run the app,

    ```bash
    $ docker-compose up
    ```

    * Access the rails app frontend by visiting `http://0.0.0.0:3000/`
    * Access Mailhog inbox by visiting `http://0.0.0.0:8025/` (You will receive all emails going out of the application here)
    * Access Sidekiq Web UI by visiting `http://0.0.0.0:3000/sidekiq` (You need to login with administrator account to access sidekiq)

    #### Login with credentials
    ```
        url: http://localhost:3000
        user_name: john@acme.inc
        password: 123456
    ````

6. To stop the app,

    ```bash
    $ docker-compose down
    ```

### Running rspec tests

For running the complete rspec tests,

    ```bash
    $ docker-compose run --rm rails bundle exec rspec
    ```

For running specific test,

    ```bash
    $ docker-compose run --rm rails bundle exec rspec spec/<path-to-file>:<line-number>
    ```

## Production environment

To debug the production build locally, set `SECRET_KEY_BASE` environment variable in your `.env` file and then run the below commands:

    ```bash
    $ docker-compose -f docker-compose.production.yaml build
    $ docker-compose -f docker-compose.production.yaml up
    ```

## Debugging mode

To use debuggers like `byebug` or `binding.pry`, use the following command to bring up the app instead of `docker-compose up`.

    ```bash
       $ docker-compose run --rm --service-port rails  
    ```


## Troubleshooting
If there is an update to any of the following 
- `dockerfile`
- `gemfile`
- `package.json` 
- schema change

Make sure to rebuild the containers and run `db:reset`.

    ```bash
    $ docker-compose down
    $ docker-compose build
    $ docker-compose run --rm rails bundle exec rails db:reset
    $ docker-compose up
    ```

# Chatscommerce Web UI/Server


## Development environment setup
### Docker
1. Clone the repository.
    ```
    git clone https://github.com/chatwoot/chatwoot.git
    ```

2. Make a copy of the example environment file and modify it as required.
    ```
    # Navigate to Chatwoot
    cd chatwoot
    cp .env.example .env
    # Update redis and postgres passwords
    nano .env
    # Update docker-compose.yaml with the same postgres password
    nano docker-compose.yaml
    ```

3. Build the images.
    ```
    # Build base image first
    docker compose build base

    # Build the server and worker
    docker compose build
    ```

4. After building the image or destroying the stack, you would have to reset the database using the following command.
    ```
    docker compose run --rm rails bundle exec rails db:chatwoot_prepare
    ```

5. To run the app:
    ```
    docker compose up
    ```

* Access the rails app frontend by visiting http://0.0.0.0:3000/
* Access Mailhog inbox by visiting http://0.0.0.0:8025/ (You will receive all emails going out of the application here)

6. To stop the app:
    ```
    docker compose down
    ```
​

## Daily Development Commands

```
# Start development environment
docker compose up

# View logs
docker compose logs -f rails

# Access Rails console
docker compose exec rails bundle exec rails console

# Run migrations
docker compose exec rails bundle exec rails db:migrate

# Install new gems
docker compose exec rails bundle install

# Restart a service
docker compose restart rails

# Stop all services
docker compose down

# Stop and remove volumes (reset database)
docker compose down -v
```
​

## Troubleshooting
If there is an update to any of the following:

* dockerfile
* gemfile
* package.json
* schema change

Make sure to rebuild the containers and run db:reset.

```
docker compose down
docker compose build
docker compose run --rm rails bundle exec rails db:reset
docker compose up
```

## Deployment

For other supported options, checkout our [deployment page](https://chatwoot.com/deploy).

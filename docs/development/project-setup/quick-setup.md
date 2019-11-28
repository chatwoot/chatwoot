---
path: "/docs/quick-setup"
title: "Quick Setup"
---

### Install Ruby dependencies

Use the following command to install ruby dependencies.

```bash
bundle
```

### Install JavaScript dependencies

```bash
yarn
```

This would install all required dependencies for Chatwoot application.

Please refer to [environment-variables](./environment-variables) to read on setting environment variables.

### Setup rails server

```bash
# run db migrations
bundle exec rake db:create
bundle exec rake db:reset

# fireup the server
foreman start -f Procfile.dev
```

### Login with credentials

```bash
http://localhost:3000
user name: john@acme.inc
password: 123456
```

### Docker for development

If you are using docker for the development follow the following steps.

We are running postgres and redis services along with chatwoot server using docker-compose.

Create a volume for postgres and redis so that you data will persist even if the containers goes down.

```bash
docker volume create --name=postgres
docker volume create --name=redis
docker-compose build
```

Remove the `node_modules` directory from the root if it exists and run the following command.

```bash
docker-compose run server yarn install
```

If in case you encounter a seeding issue or you want reset the database you can do it using the following command :

```bash
docker-compose run server bundle exec rake db:reset
```

This command essentially runs postgres and redis containers and then run the rake command inside the chatwoot server container.

Now you should be able to run :

```bash
docker-compose up
```

to see the application up and running.

### Docker for production

You can use our official Docker image from [https://hub.docker.com/r/chatwoot/chatwoot](https://hub.docker.com/r/chatwoot/chatwoot)

```bash
docker pull chatwoot/chatwoot
```

You can create an image yourselves by running the following command on the root directory.

```bash
docker image build -f docker/Dockerfile .
```

This will build the image which you can depoy in Kubernetes (GCP, Openshift, AWS, Azure or anywhere), Amazon ECS or Docker Swarm. You can tag this image and push this image to docker registry of your choice.

Remember to make the required environment variables available during the deployment.

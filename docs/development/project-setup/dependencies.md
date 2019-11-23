---
path: "/docs/dependencies"
title: "Project Dependencies"
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


### Docker for development

If you are using docker for the development follow the following steps.

We are running postgres and redis services along with chatwoot server using docker-compose.

Create a volume for postgres so that you data will persist even if the postgress container goes down.

```bash
docker volume create --name=postgres
docker-compose build
```

Remove the `node_modules` directory from the root if it exists and run the following command.
```bash
docker-compose run server yarn install
```

Now you should be able to run :

```bash
docker-compose up
```

to see the application up and running.

If in case you encounter a seeding issue or you want reset the database you can do it using the following command

```bash
docker-compose run server bundle exec rake db:seed
```

This command essentially runs postgres and redis containers and then run the rake command inside the chatwoot server container.


### Docker for production

On the root directory run the following command :

```bash
docker image build -f docker/Dockerfile .
```

This will build the image which you can depoy in Kubernetes (GCP, Openshift, AWS, Azure or anywhere), Amazon ECS or Docker Swarm. You can tag this image and push this image to docker registry of your choice. 

Remember to make the required environment variables available during the deployment.
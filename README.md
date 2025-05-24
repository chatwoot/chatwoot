<img src="./.github/screenshots/header.png#gh-light-mode-only" width="100%" alt="Header light mode"/>
<img src="./.github/screenshots/header-dark.png#gh-dark-mode-only" width="100%" alt="Header dark mode"/>

___

# Chatwoot

The modern customer support platform, an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud etc.

<p>
  <a href="https://codeclimate.com/github/chatwoot/chatwoot/maintainability"><img src="https://api.codeclimate.com/v1/badges/e6e3f66332c91e5a4c0c/maintainability" alt="Maintainability"></a>
  <img src="https://img.shields.io/circleci/build/github/chatwoot/chatwoot" alt="CircleCI Badge">
    <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/pulls/chatwoot/chatwoot" alt="Docker Pull Badge"></a>
  <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/cloud/build/chatwoot/chatwoot" alt="Docker Build Badge"></a>
  <img src="https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot" alt="Commits-per-month">
  <a title="Crowdin" target="_self" href="https://chatwoot.crowdin.com/chatwoot"><img src="https://badges.crowdin.net/e/37ced7eba411064bd792feb3b7a28b16/localized.svg"></a>
  <a href="https://discord.gg/cJXdrwS"><img src="https://img.shields.io/discord/647412545203994635" alt="Discord"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fuptime.json" alt="uptime"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fresponse-time.json" alt="response time"></a>
  <a href="https://artifacthub.io/packages/helm/chatwoot/chatwoot"><img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/artifact-hub" alt="Artifact HUB"></a>
</p>


<p>
  <a href="https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master" alt="Deploy to Heroku">
     <img width="150" alt="Deploy" src="https://www.herokucdn.com/deploy/button.svg"/>
  </a>
  <a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
     <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
  </a>
</p>

<img src="./.github/screenshots/dashboard.png#gh-light-mode-only" width="100%" alt="Chat dashboard dark mode"/>
<img src="./.github/screenshots/dashboard-dark.png#gh-dark-mode-only" width="100%" alt="Chat dashboard"/>

---

Chatwoot is the modern, open-source, and self-hosted customer support platform designed to help businesses deliver exceptional customer support experience. Built for scale and flexibility, Chatwoot gives you full control over your customer data while providing powerful tools to manage conversations across channels.

### ✨ Captain – AI Agent for Support

Supercharge your support with Captain, Chatwoot’s AI agent. Captain helps automate responses, handle common queries, and reduce agent workload—ensuring customers get instant, accurate answers. With Captain, your team can focus on complex conversations while routine questions are resolved automatically. Read more about Captain [here](https://chwt.app/captain-docs).

### 💬 Omnichannel Support Desk

Chatwoot centralizes all customer conversations into one powerful inbox, no matter where your customers reach out from. It supports live chat on your website, email, Facebook, Instagram, Twitter, WhatsApp, Telegram, Line, SMS etc.

### 📚 Help center portal

Publish help articles, FAQs, and guides through the built-in Help Center Portal. Enable customers to find answers on their own, reduce repetitive queries, and keep your support team focused on more complex issues.

### 🗂️ Other features

#### Collaboration & Productivity

- Private Notes and @mentions for internal team discussions.
- Labels to organize and categorize conversations.
- Keyboard Shortcuts and a Command Bar for quick navigation.
- Canned Responses to reply faster to frequently asked questions.
- Auto-Assignment to route conversations based on agent availability.
- Multi-lingual Support to serve customers in multiple languages.
- Custom Views and Filters for better inbox organization.
- Business Hours and Auto-Responders to manage response expectations.
- Teams and Automation tools for scaling support workflows.
- Agent Capacity Management to balance workload across the team.

#### Customer Data & Segmentation
- Contact Management with profiles and interaction history.
- Contact Segments and Notes for targeted communication.
- Campaigns to proactively engage customers.
- Custom Attributes for storing additional customer data.
- Pre-Chat Forms to collect user information before starting conversations.

#### Integrations
- Slack Integration to manage conversations directly from Slack.
- Dialogflow Integration for chatbot automation.
- Dashboard Apps to embed internal tools within Chatwoot.
- Shopify Integration to view and manage customer orders right within Chatwoot.
- Use Google Translate to translate messages from your customers in realtime.
- Create and manage Linear tickets within Chatwoot.

#### Reports & Insights
- Live View of ongoing conversations for real-time monitoring.
- Conversation, Agent, Inbox, Label, and Team Reports for operational visibility.
- CSAT Reports to measure customer satisfaction.
- Downloadable Reports for offline analysis and reporting.

## ✅ Prerequisties 
### Install all of the pre-requisites:

  #### 🛳️ Docker
- Docker: (https://docs.docker.com/get-docker/)
- Docker Compose: (https://docs.docker.com/compose/install/)

#### Ruby v3.2 or higher:
  Chatwoot uses Ruby and RVM. Please refer to your specific operating system to install Ruby and RVM appropriately
  - MacOS: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/mac-os#install-rvm-or-rbenv)
  - Ubuntu: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/ubuntu/#installing-ruby)
  - Windows 10: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/windows#installing-rvm--ruby)

#### Node.JS: 
  Use [nvm](https://github.com/nvm-sh/nvm) or [fnm](https://github.com/Schniz/fnm) for version management
  Otherwise, please refer to your specific operating system to install Node.JS appropriately:
  - MacOS: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/mac-os#install-nodejs)
  - Ubuntu: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/ubuntu/#install-nodejs)
  - Windows 10: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/windows#install-nodejs)

#### PNPM:
 - Install PNPM: (https://pnpm.io/installation)

#### PostgresSQL 
Please refer to your specific operating system to install PostgresSQL appropriately: 
  - MACOS: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/mac-os#install-postgresql)
  - Ubuntu: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/ubuntu/#installing-postgresql)
  - Windows 10: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/windows#installing-postgresql)

#### 🕹️ Redis (version 7.0 or higher):
  - MacOS: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/mac-os#install-redis)
  - Ubuntu: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/ubuntu/#installing-redis)
  - Windows 10: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/windows#installing-redis)

#### 🪄 ImageMagick:
  - Installation: (https://imagemagick.org/script/download.php)

#### Git: 
  - Installation: (https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

#### 🏎️ Speed up the installation process using "Make" command:
  - Setup Guide: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/make#install-ruby--javascript-dependencies)


### 🤔 Unsure of any specific pre-requisites to install as per your operating system? Check out the links below to double check: 
  - MACOS Setup Guide: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/macos/)
  - Ubuntu Setup Guide: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/ubuntu/)
  - Windows 10 Setup Guide: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/windows/)
  - Docker Setup Guide: (https://www.chatwoot.com/docs/contributing-guide/environment-setup/docker)

## 💻 Front-end & Back-end environments
  Please go back and check that the appropriate prerequisites are installed as per your operating system. 

  Now that you've done it, let's begin the front-end and back-end setup :)

  ### 1. Clone the Repo:

    # change location to the path you want chatwoot to be installed
    cd ~

    # clone the repo and cd to chatwoot dir
    git clone https://github.com/chatwoot/chatwoot.git
    cd chatwoot

  ### 2. Install Ruby & Javascript dependencies:

    Use the following command to run **bundle && pnpm install** to install ruby and Javascript dependencies.
    <b> make burn </b>
    It's important to note that this would install all required dependencies for Chatwoot application. 
    Should errors pop up, please refer to (https://www.chatwoot.com/docs/contributing-guide/common-errors#pg-gem-installation-error)

  ### 3. 🌎 Setup environment variables

    **cp .env.example .env**

  ##### Please refer to the following link setting up environment variables 
  
    https://www.chatwoot.com/docs/contributing-guide/environment-variables 

  ### 4. Setup Rails Server

      # run db migrations
      make db
      # fireup the server
      foreman start -f Procfile.dev
    
  ### 5. Docker development. PLEASE NOTE: IF YOU ARE DEVELOPING WITH DOCKER, DO THIS PART. Skip otherwise


  #### 1. Type the following commands IN ORDER
    
       # build base image first
      docker compose build base

       # build the server and worker
      docker compose build   

       # prepare the database
      docker compose exec rails bundle exec rails db:chatwoot_prepare

  #### 2. Docker Compose Up

  ##### To summarize, the Docker Compose Up consists of a Chatwoot server, Postgres, Redis, and webpacker-dev-server
      
  ##### Run the following command
    
        docker compose run --rm rails bundle exec rails db:chatwoot_prepare

  ##### Once all of the above is done, **copy and paste the link http://localhost:3000 onto your web search engine**

  ##### Should you like to stop the local host execution, simply click Ctrl + C or Command + C if you have a Windows or Mac, respectively**

  ##### If you decide to change the Dockerfile's service of the build factory content, run
  
        stop 
  
  ##### then 
      
        build
      
  ##### Below is an example code snippet on how to do this:

         docker compose stop
         docker compose build
    
  ##### If you decide to reset the database or encounter a seeding issue, then type the following command:

         docker compose run -rm rails bundle exec rake db:reset

 


## 🏃‍♂️ Run the application locally 

  ### Follow the instructions below
    
      Type the localhost link into your web browser: http://localhost:3000
      Type an example username: john@acme.inc
      Type an example password: Password1!
    

## 🧪 Testing the Core Functionality

  ### Testing the chatwoot widget
  #### To access the chat widget part, simply type (or copy and paste) the following link into your web browser: 
          
          http://localhost:3000/widget_tests

  #### If you're interested to test the user setting method, type the following link:
          
          http://localhost:3000/widget_tests?setUser=true
          
  ### ✅ Debugging the Docker Server
  #### If you're interested in debugging the docker server, click the image link: https://hub.docker.com/r/chatwoot/chatwoot
          
  #### Or, simply type the following command:
      
      docker pull chatwoot/chatwoot

  #### If you'd like to create the image by yourself, simply type the following command: 
      
      docker compose -f docker-compose.production.yaml build

## Running into Errors? 

  ### If you're running into Redis connection errors such as the one below: 

      ArgumentError: invalid uri scheme

  ### It's likely that you have not properly set up the redis environment variables correctly.
  ### Please refer to the Redis dependency server section and check-out the following link: 
      https://www.chatwoot.com/docs/environment-variables

  ### Running into PG Gem errors? It's likely you're seeing the log below:
    Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

    An error occurred while installing pg (x.x.x), and Bundler cannot
    continue.
    Make sure that `gem install pg -v 'x.x.x' --source 'https://rubygems.org/'`
    succeeds before bundling.

    checking for pg_config... no
    No pg_config... trying anyway. If building fails, please try again with
     --with-pg-config=/path/to/pg_config

  ### Solution: Execute the command below
    gem install pg -v 'x.x.x' --source 'https://rubygems.org/' -- --with-pg-config=path-to-postgres-installation/12/bin/pg_config


## Documentation

Detailed documentation is available at [chatwoot.com/help-center](https://www.chatwoot.com/help-center).

## Translation process

The translation process for Chatwoot web and mobile app is managed at [https://translate.chatwoot.com](https://translate.chatwoot.com) using Crowdin. Please read the [translation guide](https://www.chatwoot.com/docs/contributing/translating-chatwoot-to-your-language) for contributing to Chatwoot.

## Branching model

We use the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model. The base branch is `develop`.
If you are looking for a stable version, please use the `master` or tags labelled as `v1.x.x`.

## Deployment

### Heroku one-click deploy

Deploying Chatwoot to Heroku is a breeze. It's as simple as clicking this button:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master)

Follow this [link](https://www.chatwoot.com/docs/environment-variables) to understand setting the correct environment variables for the app to work with all the features. There might be breakages if you do not set the relevant environment variables.


### DigitalOcean 1-Click Kubernetes deployment

Chatwoot now supports 1-Click deployment to DigitalOcean as a kubernetes app.

<a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
  <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
</a>

### Other deployment options

For other supported options, checkout our [deployment page](https://chatwoot.com/deploy).

## Security

Looking to report a vulnerability? Please refer our [SECURITY.md](./SECURITY.md) file.

## Community

If you need help or just want to hang out, come, say hi on our [Discord](https://discord.gg/cJXdrwS) server.

## Contributors

Thanks goes to all these [wonderful people](https://www.chatwoot.com/docs/contributors):

<a href="https://github.com/chatwoot/chatwoot/graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2025, Chatwoot Inc - Released under the MIT License.

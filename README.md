<p align="center">
  <img src="https://s3.us-west-2.amazonaws.com/gh-assets.chatwoot.com/brand.svg" alt="Woot-logo" width="240">

  <div align="center">A simple and elegant live chat software</div>
  <div align="center">An opensource alternative to Intercom, Zendesk, Drift, Crisp etc.</div>
</p>

<p align="center">
  <a href="https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master" alt="Deploy to Heroku">
     <img alt="Deploy" src="https://www.herokucdn.com/deploy/button.svg"/>
  </a>
</p>

___

<p align="center">
  <a href="https://codeclimate.com/github/chatwoot/chatwoot/maintainability"><img src="https://api.codeclimate.com/v1/badges/80f9e1a7c72d186289ad/maintainability" alt="Maintainability"></a>
  <img src="https://img.shields.io/circleci/build/github/chatwoot/chatwoot" alt="CircleCI Badge">
  <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/cloud/build/chatwoot/chatwoot" alt="Docker Build Badge"></a>
  <img src="https://img.shields.io/github/license/chatwoot/chatwoot" alt="License">
  <img src="https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot" alt="Commits-per-month">
  <a title="Crowdin" target="_self" href="https://chatwoot.crowdin.com/chatwoot"><img src="https://badges.crowdin.net/e/37ced7eba411064bd792feb3b7a28b16/localized.svg"></a>
  <a href="https://discord.gg/cJXdrwS"><img src="https://img.shields.io/discord/647412545203994635" alt="Discord"></a>
</p>

![ChatUI progess](https://s3.us-west-2.amazonaws.com/gh-assets.chatwoot.com/chatwoot-dashboard-assets.png)

## Background

Chatwoot is a customer support tool for instant messaging channels which can help businesses provide exceptional customer support. The development of Chatwoot started in 2016. It failed to succeed as a business and eventually shut up shop in 2017. During 2019 #Hacktoberfest, the maintainers decided to make it opensource, instead of letting the code rust in a private repo. With a pleasant surprise, Chatwoot became a trending project on Hacker News and best of all, got lots of love from the community.

Now, a failed project is back on track and the prospects are looking great. The team is back to working on the project and this time, we are building it in the open. Thanks to the ideas and contributions from the community.

## Documentation

Detailed documentation is available at [www.chatwoot.com/docs](https://www.chatwoot.com/docs).

You can find the quick setup docs [here](https://www.chatwoot.com/docs/quick-setup).

## Branching model

We use the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model. The base branch is `develop`.
If you are looking for a stable version, please use the `master` or tags labelled as `v1.x.x`. 

## Heroku one-click deploy

Deploying chatwoot to heroku is a breeze. It's as simple as clicking this button:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master)

Follow this [link](https://www.chatwoot.com/docs/environment-variables) to understand setting the correct environment variables for the app to work with all the features. There might be breakages if you do not set the relevant environment variables. This applies to deploying the docker image as well.

## Docker

Follow our [docker development guide](https://www.chatwoot.com/docs/installation-guide-docker) to develop and debug the application using `docker-compose`.

Follow our [environment variables](https://www.chatwoot.com/docs/environment-variables/) guide to setup the environment for Docker.

## Contributors ✨

Thanks goes to all these [wonderful people](https://www.chatwoot.com/docs/contributors):

<a href="https://github.com/chatwoot/chatwoot/graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2020, ThoughtWoot Inc - Released under the MIT License.

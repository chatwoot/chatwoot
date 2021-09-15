<p align="center">
  <img src="https://s3.us-west-2.amazonaws.com/gh-assets.chatwoot.com/brand.svg" alt="Woot-logo" width="240" />

  <p align="center">Customer engagement suite, an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud etc.</p>
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
    <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/pulls/chatwoot/chatwoot" alt="Docker Pull Badge"></a>
  <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/cloud/build/chatwoot/chatwoot" alt="Docker Build Badge"></a>
  <img src="https://img.shields.io/github/license/chatwoot/chatwoot" alt="License">
  <img src="https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot" alt="Commits-per-month">
  <a title="Crowdin" target="_self" href="https://chatwoot.crowdin.com/chatwoot"><img src="https://badges.crowdin.net/e/37ced7eba411064bd792feb3b7a28b16/localized.svg"></a>
  <a href="https://discord.gg/cJXdrwS"><img src="https://img.shields.io/discord/647412545203994635" alt="Discord"></a>
  <a href="https://huntr.dev/bounties/disclose"><img src="https://cdn.huntr.dev/huntr_security_badge_mono.svg" alt="Huntr"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fuptime.json" alt="uptime"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fresponse-time.json" alt="response time"></a>
</p>

<img src="https://s3.us-west-2.amazonaws.com/gh-assets.chatwoot.com/chatwoot-dashboard-assets.png" width="100%" alt="Chat dashboard"/>

Chatwoot is an open-source omnichannel customer support software. The development of Chatwoot started in 2016. It failed to succeed as a business and eventually shut up shop in 2017. During 2019 #Hacktoberfest, the maintainers decided to make it open-source, instead of letting the code rust in a private repo. With a pleasant surprise, Chatwoot became a trending project on Hacker News and best of all, got lots of love from the community.
Now, a failed project is back on track and the prospects are looking great. The team is back to working on the project and this time, we are building it in the open. Thanks to the ideas and contributions from the community.


## Features

Chatwoot gives an integrated view of conversations happening in different communication channels.

It supports the following conversation channels:

 - **Website**: Talk to your customers using our live chat widget and make use of our SDK to identify a user and provide contextual support.
 - **Facebook**: Connect your Facebook pages and start replying to the direct messages to your page.
 - **Twitter**: Connect your Twitter profiles and reply to direct messages or the tweets where you are mentioned.
 - **Whatsapp**: Connect your Whatsapp business account and manage the conversation in Chatwoot
 - **SMS**: Connect your Twilio SMS account and reply to the SMS queries in Chatwoot
 - **API Channel**: Build custom communication channels using our API channel.
 - **Email (beta)**: Forward all your email queries to Chatwoot and view it in our integrated dashboard.

Other features include:

- **Multi-brand inboxes**: Manage multiple brands or pages using a single dashboard.
- **Private notes**: Inter team communication is possible using private notes in a conversation.
- **Canned responses (Saved replies)**: Improve the response rate by adding saved replies for frequently asked questions.
- **Conversation Labels**: Use conversation labelling to create custom workflows.
- **Auto assignment**: Chatwoot intelligently assigns a ticket to the agents who have access to the inbox depending on their availability and load.
- **Conversation continuity**: If the user has provided an email address through the chat widget, Chatwoot would send an email to the customer under the agent name so that the user can continue the conversation over the email.
- **Multi-lingual support**: Chatwoot supports 10+ languages.
- **Powerful API & Webhooks**: Extend the capability of the software using Chatwoot’s webhooks and APIs.
- **Integrations**: Chatwoot natively integrates with Slack right now. Manage your conversations in Slack without logging into the dashboard.

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

### Other deployment options

Please follow [deployment architecture guide](https://www.chatwoot.com/docs/deployment/architecture) to deploy with Docker or Caprover.

## Security

Looking to report a vulnerability? Please refer our [SECURITY.md](./SECURITY.md) file.


## Community? Questions? Support ?

If you need help or just want to hang out, come, say hi on our [Discord](https://discord.gg/cJXdrwS) server.


## Contributors ✨

Thanks goes to all these [wonderful people](https://www.chatwoot.com/docs/contributors):

<a href="https://github.com/chatwoot/chatwoot/graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2021, Chatwoot Inc - Released under the MIT License.

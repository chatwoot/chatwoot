<img src="./.github/screenshots/header.png#gh-light-mode-only" width="100%" alt="Header light mode"/>
<img src="./.github/screenshots/header-dark.png#gh-dark-mode-only" width="100%" alt="Header dark mode"/>

___

# Chatwoot

The modern customer support platform, an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud etc.

<p>
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


---

## Switchable Fork — Custom Features

This repository is a fork of Chatwoot with isolated, portable custom features. Each feature is self-contained and can be copied into any other Chatwoot installation without touching upstream files beyond a minimum.

---

### Feature: Facebook Messenger Ad Referral Card

When a contact starts a conversation by clicking a Facebook ad, Chatwoot now displays the ad content (thumbnail + title) above their first message in the chat.

#### How it works

Facebook sends a `referral` object alongside the message webhook event. This fork captures it and stores it in `content_attributes.referral`. The frontend reads that data and renders an ad card at the top of the text bubble.

#### Files added by this feature

| File | Purpose |
|---|---|
| `config/initializers/facebook_ad_referral.rb` | Wires the extensions (the only file that references upstream classes) |
| `lib/integrations/facebook/ad_referral/message_parser_extension.rb` | Extracts `referral` from the webhook payload |
| `lib/integrations/facebook/ad_referral/message_builder_extension.rb` | Stores referral in `content_attributes` |
| `app/javascript/dashboard/components-next/message/ad-referral/AdReferralCard.vue` | Vue component that renders the ad card |

#### Minimal changes to upstream files

| File | Change |
|---|---|
| `app/javascript/dashboard/components-next/message/bubbles/Text/Index.vue` | 1 import line + 3 template lines |
| `app/javascript/dashboard/i18n/locale/en/conversation.json` | `AD_REFERRAL.SPONSORED` translation key |

#### Deploying to an existing Chatwoot installation

1. **Copy the new files** into the target Chatwoot repo:
   ```
   config/initializers/facebook_ad_referral.rb
   lib/integrations/facebook/ad_referral/
   app/javascript/dashboard/components-next/message/ad-referral/
   ```

2. **Edit `app/javascript/dashboard/components-next/message/bubbles/Text/Index.vue`** — add after the existing imports:
   ```js
   import AdReferralCard from 'next/message/ad-referral/AdReferralCard.vue';
   ```
   Then inside the template's `<div class="gap-3 flex flex-col">`, before `<span v-if="isEmpty">`:
   ```vue
   <AdReferralCard
     v-if="contentAttributes.referral"
     :referral="contentAttributes.referral"
   />
   ```

3. **Add the translation key** to `app/javascript/dashboard/i18n/locale/en/conversation.json` inside the top-level `CONVERSATION` object:
   ```json
   "AD_REFERRAL": {
     "SPONSORED": "Sponsored"
   },
   ```

4. **Rebuild the frontend assets:**
   ```bash
   pnpm install
   pnpm build
   ```

5. **Restart Rails** (the initializer loads automatically on boot — no migrations required):
   ```bash
   bundle exec rails server
   # or in production: restart your Rails process / Sidekiq workers
   ```

#### Removing the feature

Delete these files and restart Rails:
```
config/initializers/facebook_ad_referral.rb
lib/integrations/facebook/ad_referral/
app/javascript/dashboard/components-next/message/ad-referral/
```
Then revert the 4 lines in `Text/Index.vue` and the i18n key.

---

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


*Chatwoot* &copy; 2017-2026, Chatwoot Inc - Released under the MIT License.

---
path: "/docs/slack-integration-setup"
title: "Setting Up Slack Integration"
---

### Register a Slack app

To use Slack Integration, you have to create a Slack app in the developer portal. You can find more details about creating Slack apps [here](https://api.slack.com/)

Once you register your Slack App, you will have to obtain the `Client Id` and `Client Secret`. These values will be available in the app settings and will be required while setting up Chatwoot environment variables.

### Configure the Slack app

1) Create a slack app and add it to your development workspace.
2) Obtain the `Client Id` and `Client Secret` for the app and configure it in your Chatwoot environment variables.
3) Head over to the `OAuth & permissions` section under `features` tab.
4) In the redirect URLs, Add your Chatwoot installation base url.
5) In the scopes section configure the given scopes for bot token scopes. `commands,chat:write,channels:read,channels:manage,channels:join,groups:write,im:write,mpim:write,users:read,users:read.email,chat:write.customize,channels:history,groups:history,mpim:history,im:history`
6) Head over to the `events subscriptions` section under `features` tab.
7) Enable events and configure the given request url `{chatwoot installation url}/api/v1/integrations/webhooks`
8) Subscribe to the following bot events `message.channels` , `message.groups`, `message.im`, `message.mpim`
9) Connect slack integration on Chatwoot app and get productive.

### Configuring the environment variables in Chatwoot

Configure the following Chatwoot environment variables with the values you have obtained during the slack app setup.

```bash
SLACK_CLIENT_ID=
SLACK_CLIENT_SECRET=
```

### Test your setup

1. Ensure that you are receiving the Chatwoot messages in the `customer-conversations` channel.
2. Add a message to that thread and ensure it is coming back on to Chatwoot
3. Add `note:` or `private:` in front on the Slack message see if it is coming out as private notes
4. If your Slack member's email matches their email on Chatwoot, the messages will be associated with their Chatwoot user account.

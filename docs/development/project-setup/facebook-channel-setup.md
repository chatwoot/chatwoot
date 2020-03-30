---
path: "/docs/facebook-setup"
title: "Setting Up Facebook"
---

### Register A Facebook App

To use Facebook Channel, you have to create an Facebook app in developer portal. You can find more details about creating Facebook channels [here](https://developers.facebook.com/docs/apps/#register)

Once you register your Facebook App, you will have to obtain the `App Id` and `App Secret` . These values will be available in the app settings and will be required while setting up Chatwoot environment variables.

### Configure the Facebook App

1) In the app settings add your `Chatwoot installation url` as your app domain.
2) In the products section in your app settings page, Add Messenger
3) Go to the Messenger settings and configure the call Back URL with `{your_chatwoot_url}/bot`
4) Configure a `verify token`, you will need this value for configuring the chatwoot environment variables
5) You might have to add a Facebook page to your `Access Tokens` section in your Messenger settings page if your app is still in development.
6) You will also have to add your Facebook page to webhooks sections in your messenger settings with all the webhook events checked.

### Configuring the Environment Variables in Chatwoot

Configure the following Chatwoot environment variables with the values you have obtained during the facebook app setup.

```bash
FB_VERIFY_TOKEN=
FB_APP_SECRET=
FB_APP_ID=
```

### Things to note before going into production.

Before you can start using your Facebook app in production, you will have to get it verified by Facebook. Refer the [docs](https://developers.facebook.com/docs/apps/review/) on getting your app verified.

### Developing or Testing Facebook Integration in You Local

Install [ngrok](https://ngrok.com/docs) on your machine. This will be required since Facebook Messenger API's will only communicate via https.

```bash
brew cask install ngrok
```

Configure ngrok to route to your Rails server port.

```bash
ngrok http 3000
```

Go to Facebook developers page and navigate into your app settings. In the app settings, add `localhost` as your app domain.
In the Messenger settings page, configure the callback url with the following value.

```bash
{your_ngrok_url}/bot
```

Update verify token in your Chatwoot environment variables.

You will also have to add a Facebook page to your `Access Tokens` section in your Messenger settings page.
Restart the Chatwoot local server. Your Chatwoot setup will be ready to receive Facebook messages.

### Test your local Setup

1. After finishing the set up above, [create a Facebook inbox](/docs/channels/facebook) after logging in to your Chatwoot Installation.
2. Send a message to your page from Facebook.
3. Wait and confirm incoming requests to `/bot` endpoint in your ngrok screen.

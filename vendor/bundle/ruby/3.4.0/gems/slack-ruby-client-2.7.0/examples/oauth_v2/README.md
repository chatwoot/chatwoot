Obtain a user OAuth token from Slack.

Create a Slack app [here](https://api.slack.com/tutorials/tracks/getting-a-token). 

The new app has a pre-configured User OAuth Token which you can use for most of the examples.
However you may want to obtain a token for a different user, which can be accomplished as follows.

To test locally use [ngrok](https://ngrok.com/) to expose your local server to the internet. 

```sh
ngrok http 4242
```

Add the ngrok URL to the app's "Redirect URLs" under "OAuth & Permissions" in the app's settings.

Create a `.env` file with the following:

```
SLACK_CLIENT_ID=[App Client ID]
SLACK_CLIENT_SECRET=[App Client Secret]
REDIRECT_URI=[Your ngrok URL, e.g. https://...ngrok-free.app]
SCOPE=[Bot User OAuth Scopes Requested]
USER_SCOPE=[User OAuth Token Scopes Requested]
```

Run the example.

```sh
bundle install
bundle exec dotenv ruby oauth_v2.rb 
```

A browser window will open to complete the OAuth flow.

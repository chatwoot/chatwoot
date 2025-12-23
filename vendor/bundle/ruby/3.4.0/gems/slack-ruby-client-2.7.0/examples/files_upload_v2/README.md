Samples for using `files_upload_v2`.

## Usage

Create a Slack app and obtain a User OAuth Token [here](https://api.slack.com/tutorials/tracks/getting-a-token) or use the [oauth_v2](../oauth_v2) example to obtain a User OAuth Token.
Make sure to select `files:write` and `files:read` scopes under "User Token Scopes".

Create `.env` file with `SLACK_API_TOKEN` or set the `SLACK_API_TOKEN` environment variable.

```
bundle install
bundle exec dotenv ruby files_upload_v2.rb
```

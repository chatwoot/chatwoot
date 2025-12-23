[![Gem Version](https://badge.fury.io/rb/omniauth-google-oauth2.svg)](https://badge.fury.io/rb/omniauth-google-oauth2)

# OmniAuth Google OAuth2 Strategy

Strategy to authenticate with Google via OAuth2 in OmniAuth.

Get your API key at: https://code.google.com/apis/console/  Note the Client ID and the Client Secret.

For more details, read the Google docs: https://developers.google.com/accounts/docs/OAuth2

## Installation

Add to your `Gemfile`:

```ruby
gem 'omniauth-google-oauth2'
```

Then `bundle install`.

## Google API Setup

* Go to 'https://console.developers.google.com'
* Select your project.
* Go to Credentials, then select the "OAuth consent screen" tab on top, and provide an 'EMAIL ADDRESS' and a 'PRODUCT NAME'
* Wait 10 minutes for changes to take effect.

## Usage

Here's an example for adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
end
OmniAuth.config.allowed_request_methods = %i[get]
```

You can now access the OmniAuth Google OAuth2 URL: `/auth/google_oauth2`

For more examples please check out `examples/omni_auth.rb`

[Using Devise? Skip the above and jump down to the Devise section!](#devise) After setting up the provider via Devise, you can reference the configurations below.

NOTE: While developing your application, if you change the scope in the initializer you will need to restart your app server. Remember that either the 'email' or 'profile' scope is required!

## Configuration

You can configure several options, which you pass in to the `provider` method via a hash:

* `scope`: A comma-separated list of permissions you want to request from the user. See the [Google OAuth 2.0 Playground](https://developers.google.com/oauthplayground/) for a full list of available permissions. Caveats:
  * The `email` and `profile` scopes are used by default. By defining your own `scope`, you override these defaults, but Google requires at least one of `email` or `profile`, so make sure to add at least one of them to your scope!
  * Scopes starting with `https://www.googleapis.com/auth/` do not need that prefix specified. So while you can use the smaller scope `books` since that permission starts with the mentioned prefix, you should use the full scope URL `https://docs.google.com/feeds/` to access a user's docs, for example.

* `redirect_uri`: Override the redirect_uri used by the gem.

* `prompt`: A space-delimited list of string values that determines whether the user is re-prompted for authentication and/or consent. Possible values are:
  * `none`: No authentication or consent pages will be displayed; it will return an error if the user is not already authenticated and has not pre-configured consent for the requested scopes. This can be used as a method to check for existing authentication and/or consent.
  * `consent`: The user will always be prompted for consent, even if they have previously allowed access a given set of scopes.
  * `select_account`: The user will always be prompted to select a user account. This allows a user who has multiple current account sessions to select one amongst them.

  If no value is specified, the user only sees the authentication page if they are not logged in and only sees the consent page the first time they authorize a given set of scopes.

* `image_aspect_ratio`: The shape of the user's profile picture. Possible values are:
  * `original`: Picture maintains its original aspect ratio.
  * `square`: Picture presents equal width and height.

  Defaults to `original`.

* `image_size`: The size of the user's profile picture. The image returned will have width equal to the given value and variable height, according to the `image_aspect_ratio` chosen. Additionally, a picture with specific width and height can be requested by setting this option to a hash with `width` and `height` as keys. If only `width` or `height` is specified, a picture whose width or height is closest to the requested size and requested aspect ratio will be returned. Defaults to the original width and height of the picture.

* `name`: The name of the strategy. The default name is `google_oauth2` but it can be changed to any value, for example `google`. The OmniAuth URL will thus change to `/auth/google` and the `provider` key in the auth hash will then return `google`.

* `access_type`: Defaults to `offline`, so a refresh token is sent to be used when the user is not present at the browser. Can be set to `online`. More about [offline access](https://developers.google.com/identity/protocols/OAuth2WebServer#offline)

* `hd`: (Optional) Limit sign-in to a particular Google Apps hosted domain. This can be simply string `'domain.com'` or an array `%w(domain.com domain.co)`. More information at: https://developers.google.com/accounts/docs/OpenIDConnect#hd-param

* `jwt_leeway`: Number of seconds passed to the JWT library as leeway. Defaults to 60 seconds. Note this only works if you use jwt 2.1, as the leeway option was removed in later versions.

* `skip_jwt`: Skip JWT processing. This is for users who are seeing JWT decoding errors with the `iat` field. Always try adjusting the leeway before disabling JWT processing.

* `login_hint`: When your app knows which user it is trying to authenticate, it can provide this parameter as a hint to the authentication server. Passing this hint suppresses the account chooser and either pre-fill the email box on the sign-in form, or select the proper session (if the user is using multiple sign-in), which can help you avoid problems that occur if your app logs in the wrong user account. The value can be either an email address or the sub string, which is equivalent to the user's Google+ ID.

* `include_granted_scopes`: If this is provided with the value true, and the authorization request is granted, the authorization will include any previous authorizations granted to this user/application combination for other scopes. See Google's [Incremental Authorization](https://developers.google.com/accounts/docs/OAuth2WebServer#incrementalAuth) for additional details.

* `enable_granular_consent`: If this is provided with the value true, users can choose to only grant access to specific data. See Google's [How to handle granular permissions](https://developers.google.com/identity/protocols/oauth2/resources/granular-permissions) guide for additional details.

* `openid_realm`: Set the OpenID realm value, to allow upgrading from OpenID based authentication to OAuth 2 based authentication. When this is set correctly an `openid_id` value will be set in `['extra']['id_info']` in the authentication hash with the value of the user's OpenID ID URL.

* `provider_ignores_state`: You will need to set this to `true` when using the `One-time Code Flow` below. In this flow there is no server side redirect that would set the state.

* `overridable_authorize_options`: By default, all `authorize_options` can be overridden with request parameters. You can restrict the behavior by using this option.

Here's an example of a possible configuration where the strategy name is changed, the user is asked for extra permissions, the user is always prompted to select their account when logging in and the user's profile picture is returned as a thumbnail:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],
    {
      scope: 'email, profile, http://gdata.youtube.com',
      prompt: 'select_account',
      image_aspect_ratio: 'square',
      image_size: 50
    }
end
```

## Auth Hash

Here's an example of an authentication hash available in the callback by accessing `request.env['omniauth.auth']`:

```ruby
{
  "provider" => "google_oauth2",
  "uid" => "100000000000000000000",
  "info" => {
    "name" => "John Smith",
    "email" => "john@example.com",
    "first_name" => "John",
    "last_name" => "Smith",
    "image" => "https://lh4.googleusercontent.com/photo.jpg",
    "urls" => {
      "google" => "https://plus.google.com/+JohnSmith"
    }
  },
  "credentials" => {
    "token" => "TOKEN",
    "refresh_token" => "REFRESH_TOKEN",
    "expires_at" => 1496120719,
    "expires" => true
  },
  "extra" => {
    "id_token" => "ID_TOKEN",
    "id_info" => {
      "azp" => "APP_ID",
      "aud" => "APP_ID",
      "sub" => "100000000000000000000",
      "email" => "john@example.com",
      "email_verified" => true,
      "at_hash" => "HK6E_P6Dh8Y93mRNtsDB1Q",
      "iss" => "accounts.google.com",
      "iat" => 1496117119,
      "exp" => 1496120719
    },
    "raw_info" => {
      "sub" => "100000000000000000000",
      "name" => "John Smith",
      "given_name" => "John",
      "family_name" => "Smith",
      "profile" => "https://plus.google.com/+JohnSmith",
      "picture" => "https://lh4.googleusercontent.com/photo.jpg?sz=50",
      "email" => "john@example.com",
      "email_verified" => "true",
      "locale" => "en",
      "hd" => "company.com"
    }
  }
}
```

### Devise

First define your application id and secret in `config/initializers/devise.rb`. Do not use the snippet mentioned in the [Usage](https://github.com/zquestz/omniauth-google-oauth2#usage) section.

Configuration options can be passed as the last parameter here as key/value pairs.

```ruby
config.omniauth :google_oauth2, 'GOOGLE_CLIENT_ID', 'GOOGLE_CLIENT_SECRET', {}
```
NOTE: If you are using this gem with devise with above snippet in `config/initializers/devise.rb` then do not create `config/initializers/omniauth.rb` which will conflict with devise configurations.

Then add the following to 'config/routes.rb' so the callback routes are defined.

```ruby
devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
```

Make sure your model is omniauthable. Generally this is "/app/models/user.rb"

```ruby
devise :omniauthable, omniauth_providers: [:google_oauth2]
```

Then make sure your callbacks controller is setup.

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb:

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
      # You need to implement the method below in your model (e.g. app/models/user.rb)
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
        sign_in_and_redirect @user, event: :authentication
      else
        session['devise.google_data'] = request.env['omniauth.auth'].except('extra') # Removing extra as it can overflow some session stores
        redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
      end
  end
end
```

and bind to or create the user

```ruby
# app/models/user.rb

def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data['email']).first

    # Uncomment the section below if you want users to be created if they don't exist
    # unless user
    #     user = User.create(name: data['name'],
    #        email: data['email'],
    #        password: Devise.friendly_token[0,20]
    #     )
    # end
    user
end
```

For your views you can login using:

```erb
<%# omniauth-google-oauth2 1.0.x uses OmniAuth 2 and requires using HTTP Post to initiate authentication: %>
<%= link_to "Sign in with Google", user_google_oauth2_omniauth_authorize_path, method: :post %>

<%# omniauth-google-oauth2 prior 1.0.0: %>
<%= link_to "Sign in with Google", user_google_oauth2_omniauth_authorize_path %>

<%# Devise prior 4.1.0: %>
<%= link_to "Sign in with Google", user_omniauth_authorize_path(:google_oauth2) %>
```

An overview is available at https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview

### One-time Code Flow (Hybrid Authentication)

Google describes the One-time Code Flow [here](https://developers.google.com/identity/sign-in/web/server-side-flow).  This hybrid authentication flow has significant functional and security advantages over a pure server-side or pure client-side flow.  The following steps occur in this flow:

1. The client (web browser) authenticates the user directly via Google's JS API.  During this process assorted modals may be rendered by Google.
2. On successful authentication, Google returns a one-time use code, which requires the Google client secret (which is only available server-side).
3. Using a AJAX request, the code is POSTed to the Omniauth Google OAuth2 callback.
4. The Omniauth Google OAuth2 gem will validate the code via a server-side request to Google.  If the code is valid, then Google will return an access token and, if this is the first time this user is authenticating against this application, a refresh token.  Both of these should be stored on the server.  The response to the AJAX request indicates the success or failure of this process.

This flow is immune to replay attacks, and conveys no useful information to a man in the middle.

The omniauth-google-oauth2 gem supports this mode of operation when `provider_ignores_state` is set to `true`.  Implementors simply need to add the appropriate JavaScript to their web page, and they can take advantage of this flow.  An example JavaScript snippet follows.

```javascript
// Basic hybrid auth example following the pattern at:
// https://developers.google.com/identity/sign-in/web/reference

<script src="https://apis.google.com/js/platform.js?onload=init" async defer></script>

...

function init() {
  gapi.load('auth2', function() {
    // Ready.
    $('.google-login-button').click(function(e) {
      e.preventDefault();

      gapi.auth2.authorize({
        client_id: 'YOUR_CLIENT_ID',
        cookie_policy: 'single_host_origin',
        scope: 'email profile',
        response_type: 'code'
      }, function(response) {
        if (response && !response.error) {
          // google authentication succeed, now post data to server.
          jQuery.ajax({type: 'POST', url: '/auth/google_oauth2/callback', data: response,
            success: function(data) {
              // response from server
            }
          });
        } else {
          // google authentication failed
        }
      });
    });
  });
};
```

#### Note about mobile clients (iOS, Android)

The documentation at https://developers.google.com/identity/sign-in/ios/offline-access specifies the _REDIRECT_URI_ to be either a set value or an EMPTY string for mobile logins to work. Else, you will run into _redirect_uri_mismatch_ errors.

In that case, ensure to send an additional parameter `redirect_uri=` (empty string) to the `/auth/google_oauth2/callback` URL from your mobile device.

#### Note about CORS

If you're making POST requests to `/auth/google_oauth2/callback` from another domain, then you need to make sure `'X-Requested-With': 'XMLHttpRequest'` header is included with your request, otherwise your server might respond with `OAuth2::Error, : Invalid Value` error.

#### Getting around the `redirect_uri_mismatch` error (See [Issue #365](https://github.com/zquestz/omniauth-google-oauth2/issues/365))

If you are struggling with a persistent `redirect_uri_mismatch`, you can instead pass the `access_token` from [`getAuthResponse`](https://developers.google.com/identity/sign-in/web/reference#googleusergetauthresponseincludeauthorizationdata) directly to the `auth/google_oauth2/callback` endpoint, like so:

```javascript
// Initialize the GoogleAuth object
let googleAuth;
gapi.load('client:auth2', async () => {
  await gapi.client.init({ scope: '...', client_id: '...' });
  googleAuth = gapi.auth2.getAuthInstance();
});

// Call this when the Google Sign In button is clicked
async function signInGoogle() {
  const googleUser = await googleAuth.signIn(); // wait for the user to authorize through the modal
  const { access_token } = googleUser.getAuthResponse();

  const data = new FormData();
  data.append('access_token', access_token);

  const response = await api.post('/auth/google_oauth2/callback', data)
  console.log(response);
}
```

#### Using Axios
If you're making a GET resquests from another domain using `access_token`.
```
axios
  .get(
    'url(path to your callback}',
    { params: { access_token: 'token' } },
    headers....
    )
```

If you're making a POST resquests from another domain using `access_token`.
```
axios
  .post(
    'url(path to your callback}',
    { access_token: 'token' },
    headers....
    )

--OR--

axios
  .post(
    'url(path to your callback}',
    null,
      {
        params: {
          access_token: 'token'
        },
        headers....
      }
    )
```

## Fixing Protocol Mismatch for `redirect_uri` in Rails

Just set the `full_host` in OmniAuth based on the Rails.env.

```
# config/initializers/omniauth.rb
OmniAuth.config.full_host = Rails.env.production? ? 'https://domain.com' : 'http://localhost:3000'
```

## License

Copyright (c) 2018 by Josh Ellithorpe

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

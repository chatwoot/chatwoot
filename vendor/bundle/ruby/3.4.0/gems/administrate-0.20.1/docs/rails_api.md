---
title: Rails API
---

Since Rails 5.0, we've been able to have API only applications. Yet, sometimes
we still want to have an admin.

To get this working, we recommend updating this config:

```ruby
# config/application.rb
config.api_only = false
```

That means, when your app _boots_, we'll have access to flashes and such. We
also don't use your `ApplicationController`. Instead, Administrate provides its
own. Meaning you're free to specify `ActionController::API` as your parent
controller to make sure no flash, session, or cookie middleware is used by your
API.

Alternatively, if your application needs to have `config.api_only = true`, we
recommend you add the following lines to your `config/application.rb`

```ruby
# Enable Flash, Cookies, MethodOverride for Administrate Gem
config.middleware.use ActionDispatch::Flash
config.session_store :cookie_store
config.middleware.use ActionDispatch::Cookies
config.middleware.use ActionDispatch::Session::CookieStore, config.session_options
config.middleware.use ::Rack::MethodOverride
```

You must also ensure that all the required controller actions are available
and accessible as routes since generators in API-only applications only
generate some of the required actions. Here is an example:

```ruby
# routes.rb
namespace :admin do
  resources :name, only: %i(index show new create edit update destroy)
end

# names_controller.rb
# Ensure each of those methods are defined
```

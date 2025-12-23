---
title: Getting Started
---

Administrate is released as a Ruby gem, and can be installed on Rails
applications version 6.0 or greater. We support Ruby 3.0 and up.

First, add the following to your Gemfile:

```ruby
# Gemfile
gem "administrate"
```

Re-bundle with `bundle install`, then run the installer:

```bash
$ rails generate administrate:install
```

The installer adds some new routes to your `config/routes.rb`,
and creates a controller at `app/controllers/admin/application_controller.rb`

In addition, the generator creates a `Dashboard` and a `Controller` for each of
your ActiveRecord resources:

- `app/controllers/admin/foos_controller.rb`
- `app/dashboards/foo_dashboard.rb`

The `Admin::ApplicationController` can be customized to add
authentication logic, authorization, pagination,
or other controller-level concerns.

You will also want to add a `root` route to show a dashboard when you go to `/admin`.

```ruby
Rails.application.routes.draw do
  namespace :admin do
    # Add dashboard for your models here
    resources :customers
    resources :orders

    root to: "customers#index" # <--- Root route
  end
 end
```

The routes can be customized to show or hide
different models on the dashboard.

Each `FooDashboard` specifies which attributes should be displayed
on the admin dashboard for the `Foo` resource.

Each `Admin::FooController` can be overwritten to specify custom behavior.

Once you have Administrate installed,
visit <http://localhost:3000/admin> to see your new dashboard in action.

### Errors about assets?

If your apps uses Sprockets 4, you'll need to add Administrate's assets to
your `manifest.js` file. To do this, add these two lines to the file:

```
//= link administrate/application.css
//= link administrate/application.js
```

Otherwise, your app will show you this error:

```
Asset `administrate/application.css` was not declared to be precompiled in production.
Declare links to your assets in `app/assets/config/manifest.js`.
```

For more information on why this is necessary, see Richard Schneeman's article
["Self Hosted Config: Introducing the Sprockets manifest.js"][]

[schneems]: https://www.schneems.com/2017/11/22/self-hosted-config-introducing-the-sprockets-manifestjs

## Create Additional Dashboards

In order to create additional dashboards, pass in the resource name to
the dashboard generator. A dashboard and controller will be created.

```bash
$ rails generate administrate:dashboard Foo
```

Then add a route for the new dashboard.

```ruby
# config/routes.rb

namespace :admin do
  resources :foos
end
```

## Using a Custom Namespace

Administrate supports using a namespace other than `Admin`, such as
`Supervisor`. This will also change the route it's using:

```sh
rails generate administrate:install --namespace=supervisor
```

## Keep Dashboards Updated as Model Attributes Change

If you've installed Administrate and generated dashboards and _then_
subsequently added attributes to your models you'll need to manually add
these additions (or removals) to your dashboards.

Example:

```ruby
# app/dashboards/your_model_dashboard.rb

  ATTRIBUTE_TYPES = {
    # ...
    the_new_attribute: Field::String,
    # ...
  }.freeze

  SHOW_PAGE_ATTRIBUTES = [
    # ...
    :the_new_attribute,
    # ...
  ].freeze

  FORM_ATTRIBUTES = [
    # ...
    :the_new_attribute,
    # ...
  ].freeze

  COLLECTION_ATTRIBUTES = [
    # ...
    :the_new_attribute, # if you want it on the index, also.
    # ...
  ].freeze
```

It's recommended that you make this change at the same time as you add the
attribute to the model.

The alternative way to handle this is to re-run `rails g administrate:install`
and carefully pick through the diffs. This latter method is probably more
cumbersome.

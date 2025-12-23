---
title: Customizing controller actions
---

When you install Administrate into your app,
we generate empty controllers for each of your resources.
If you want to create more complex application behavior for a dashboard,
you can overwrite controller actions.

The generated controller will look something like:

```ruby
# app/controllers/admin/foos_controller.rb

class Admin::FoosController < Admin::ApplicationController

  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  # def update
  #   foo = Foo.find(params[:id])
  #   foo.update(params[:foo])
  #   send_foo_updated_email
  # end

  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  # def scoped_resource
  #  if current_user.super_admin?
  #    resource_class
  #  else
  #    resource_class.with_less_stuff
  #  end
  # end
end
```

## Customizing Actions

To disable certain actions globally, you can disable their
routes in `config/routes.rb`, using the usual Rails
facilities for this. For example:

```ruby
Rails.application.routes.draw do
  # ...
  namespace :admin do
    # ...

    # Payments can only be listed or displayed
    resources :payments, only: [:index, :show]
  end
end
```

## Customizing Default Sorting

To set the default sorting on the index action you could override `default_sorting_attribute` or `default_sorting_direction` in your dashboard controller like this:

```ruby
def default_sorting_attribute
  :age
end

def default_sorting_direction
  :desc
end
```

## Customizing Redirects after actions

To set custom redirects after the actions `create`, `update` and `destroy` you can override `after_resource_created_path`, `after_resource_updated_path` or `after_resource_destroyed_path` like this:

```ruby
    def after_resource_destroyed_path(_requested_resource)
      { action: :index, controller: :some_other_resource }
    end

    def after_resource_created_path(requested_resource)
      [namespace, requested_resource.some_other_resource]
    end

    def after_resource_updated_path(requested_resource)
      [namespace, requested_resource.some_other_resource]
    end
```

## Creating Records

You can perform actions after creation by passing a `block` to `super` in the
`create` method. The block will only be called if the resource is successfully
created.

```ruby
def create
  super do |resource|
    # do something with the newly created resource
  end
end
```

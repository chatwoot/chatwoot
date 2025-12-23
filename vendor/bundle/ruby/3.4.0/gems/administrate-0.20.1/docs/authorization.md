---
title: Authorization
---

The default configuration of Administrate is "authenticate-only" - once a
user is authenticated, that user has access to every action of every object.

You can add more fine-grained authorization by overriding methods in the
controller.

## Using Pundit

If your app already uses [Pundit](https://github.com/elabs/pundit) for
authorization, you just need to add one line to your
`Admin::ApplicationController`:

```ruby
include Administrate::Punditize
```

This will use all the policies from your main app to determine if the
current user is able to view a given record or perform a given action.

### Further limiting scope

You may want to limit the scope for a given user beyond what they
technically have access to see in the main app. For example, a user may
have all public records in their scope, but you want to only show *their*
records in the admin interface to reduce confusion.

In this case, you can add additional pundit `policy_namespace` in your controller
and Administrate will use the namespaced pundit policy instead.

For example:

```ruby
# app/controllers/admin/posts_controller.rb
module Admin
  class PostsController < ApplicationController
    include Administrate::Punditize

    def policy_namespace
      [:admin]
    end
  end
end

# app/policies/admin/post_policy.rb
module Admin
  class PostPolicy < ApplicationPolicy
    class Scope < Scope
      def resolve
        scope.where(owner: user)
      end
    end
  end
end
```

## Authorization without Pundit

Pundit is not necessary to implement authorization within Administrate. It is
simply a common solution that many in the community use, and for this reason
Administrate provides a plugin to work with it. However you can use a different
solution or roll out your own.

To integrate a different authorization solution, you will need to
implement some methods in `Admin::ApplicationController`
or its subclasses.

These are the methods to override, with examples:

```ruby
# Used in listings, such as the `index` actions. It
# restricts the scope of records that a user can access.
# Returns an ActiveRecord scope.
def scoped_resource
  super.where(user: current_user)
end

# Return true if the current user can access the given
# resource, false otherwise.
def authorized_action?(resource, action)
  current_user.can?(resource, action)
end
```

Additionally, the method `authorize_resource(resource)`
should throw an exception if the current user is not
allowed to access the given resource. Normally
you wouldn't need to override it, as the default
implementation uses `authorized_action?` to produce the
correct behaviour. However you may still want to override it
if you want to raise a custom error type.

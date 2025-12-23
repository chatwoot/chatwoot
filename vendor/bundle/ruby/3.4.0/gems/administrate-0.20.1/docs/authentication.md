---
title: Authenticating admin users
---

Authentication is left for you to implement after you install Administrate into
your app. It's expected that you can plugin your existing authentication
system.

The base `Admin::ApplicationController` has a `TODO` to be completed:

```ruby
class Admin::ApplicationController < Administrate::ApplicationController
  before_action :authenticate_admin

  def authenticate_admin
    # TODO Add authentication logic here.
  end
end
```

## Using Clearance

[Clearance][clearance] provides Rails authentication with email & password.

```ruby
class Admin::ApplicationController < Administrate::ApplicationController
  include Clearance::Controller
  before_action :require_login
end
```

## Using Devise

[Devise][devise] is an authentication solution for Rails with Warden. Include
the authentication method for your model as a `before_action`:

```ruby
class Admin::ApplicationController < Administrate::ApplicationController
  before_action :authenticate_user!
end
```

## Using HTTP Basic authentication

Rails includes the [`http_basic_authenticate_with`][rails-http-basic-auth]
method which can be added to your base admin controller:

```ruby
class Admin::ApplicationController < Administrate::ApplicationController
  http_basic_authenticate_with(
    name: ENV.fetch("ADMIN_NAME"),
    password: ENV.fetch("ADMIN_PASSWORD")
  )
end
```

With this approach consider using [dotenv][dotenv] to setup your environment and
avoid committing secrets in your repository.

[clearance]: https://github.com/thoughtbot/clearance
[devise]: https://github.com/plataformatec/devise
[rails-http-basic-auth]: http://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Basic.html
[dotenv]: https://github.com/bkeepers/dotenv

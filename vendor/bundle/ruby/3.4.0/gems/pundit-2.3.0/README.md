# Pundit

[![Build Status](https://secure.travis-ci.org/varvet/pundit.svg?branch=master)](https://travis-ci.org/varvet/pundit)
[![Code Climate](https://codeclimate.com/github/varvet/pundit.svg)](https://codeclimate.com/github/varvet/pundit)
[![Inline docs](http://inch-ci.org/github/varvet/pundit.svg?branch=master)](http://inch-ci.org/github/varvet/pundit)
[![Gem Version](https://badge.fury.io/rb/pundit.svg)](http://badge.fury.io/rb/pundit)

Pundit provides a set of helpers which guide you in leveraging regular Ruby
classes and object oriented design patterns to build a simple, robust and
scalable authorization system.

Links:

- [API documentation for the most recent version](http://www.rubydoc.info/gems/pundit)
- [Source Code](https://github.com/varvet/pundit)
- [Contributing](https://github.com/varvet/pundit/blob/master/CONTRIBUTING.md)
- [Code of Conduct](https://github.com/varvet/pundit/blob/master/CODE_OF_CONDUCT.md)

Sponsored by:

[<img src="https://www.varvet.com/images/wordmark-red.svg" alt="Varvet" height="50px"/>](https://www.varvet.com)

## Installation

> **Please note** that the README on GitHub is accurate with the _latest code on GitHub_. You are most likely using a released version of Pundit, so please refer to the [documentation for the latest released version of Pundit](https://www.rubydoc.info/gems/pundit).

``` sh
bundle add pundit
```

Include `Pundit::Authorization` in your application controller:

``` ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
end
```

Optionally, you can run the generator, which will set up an application policy
with some useful defaults for you:

``` sh
rails g pundit:install
```

After generating your application policy, restart the Rails server so that Rails
can pick up any classes in the new `app/policies/` directory.

## Policies

Pundit is focused around the notion of policy classes. We suggest that you put
these classes in `app/policies`. This is a simple example that allows updating
a post if the user is an admin, or if the post is unpublished:

``` ruby
class PostPolicy
  attr_reader :user, :post

  def initialize(user, post)
    @user = user
    @post = post
  end

  def update?
    user.admin? || !post.published?
  end
end
```

As you can see, this is just a plain Ruby class. Pundit makes the following
assumptions about this class:

- The class has the same name as some kind of model class, only suffixed
  with the word "Policy".
- The first argument is a user. In your controller, Pundit will call the
  `current_user` method to retrieve what to send into this argument
- The second argument is some kind of model object, whose authorization
  you want to check. This does not need to be an ActiveRecord or even
  an ActiveModel object, it can be anything really.
- The class implements some kind of query method, in this case `update?`.
  Usually, this will map to the name of a particular controller action.

That's it really.

Usually you'll want to inherit from the application policy created by the
generator, or set up your own base class to inherit from:

``` ruby
class PostPolicy < ApplicationPolicy
  def update?
    user.admin? or not record.published?
  end
end
```

In the generated `ApplicationPolicy`, the model object is called `record`.

Supposing that you have an instance of class `Post`, Pundit now lets you do
this in your controller:

``` ruby
def update
  @post = Post.find(params[:id])
  authorize @post
  if @post.update(post_params)
    redirect_to @post
  else
    render :edit
  end
end
```

The authorize method automatically infers that `Post` will have a matching
`PostPolicy` class, and instantiates this class, handing in the current user
and the given record. It then infers from the action name, that it should call
`update?` on this instance of the policy. In this case, you can imagine that
`authorize` would have done something like this:

``` ruby
unless PostPolicy.new(current_user, @post).update?
  raise Pundit::NotAuthorizedError, "not allowed to update? this #{@post.inspect}"
end
```

You can pass a second argument to `authorize` if the name of the permission you
want to check doesn't match the action name. For example:

``` ruby
def publish
  @post = Post.find(params[:id])
  authorize @post, :update?
  @post.publish!
  redirect_to @post
end
```

You can pass an argument to override the policy class if necessary. For example:

```ruby
def create
  @publication = find_publication # assume this method returns any model that behaves like a publication
  # @publication.class => Post
  authorize @publication, policy_class: PublicationPolicy
  @publication.publish!
  redirect_to @publication
end
```

If you don't have an instance for the first argument to `authorize`, then you can pass
the class. For example:

Policy:
```ruby
class PostPolicy < ApplicationPolicy
  def admin_list?
    user.admin?
  end
end
```

Controller:
```ruby
def admin_list
  authorize Post # we don't have a particular post to authorize
  # Rest of controller action
end
```

`authorize` returns the instance passed to it, so you can chain it like this:

Controller:
```ruby
def show
  @user = authorize User.find(params[:id])
end

# return the record even for namespaced policies
def show
  @user = authorize [:admin, User.find(params[:id])]
end
```

You can easily get a hold of an instance of the policy through the `policy`
method in both the view and controller. This is especially useful for
conditionally showing links or buttons in the view:

``` erb
<% if policy(@post).update? %>
  <%= link_to "Edit post", edit_post_path(@post) %>
<% end %>
```
## Headless policies

Given there is a policy without a corresponding model / ruby class,
you can retrieve it by passing a symbol.

```ruby
# app/policies/dashboard_policy.rb
class DashboardPolicy
  attr_reader :user

  # _record in this example will just be :dashboard
  def initialize(user, _record)
    @user = user
  end

  def show?
    user.admin?
  end
end
```

Note that the headless policy still needs to accept two arguments. The
second argument will just be the symbol `:dashboard` in this case which
is what is passed as the record to `authorize` below.

```ruby
# In controllers
def show
  authorize :dashboard, :show?
  ...
end
```

```erb
# In views
<% if policy(:dashboard).show? %>
  <%= link_to 'Dashboard', dashboard_path %>
<% end %>
```

## Scopes

Often, you will want to have some kind of view listing records which a
particular user has access to. When using Pundit, you are expected to
define a class called a policy scope. It can look something like this:

``` ruby
class PostPolicy < ApplicationPolicy
  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      if user.admin?
        scope.all
      else
        scope.where(published: true)
      end
    end

    private

    attr_reader :user, :scope
  end

  def update?
    user.admin? or not record.published?
  end
end
```

Pundit makes the following assumptions about this class:

- The class has the name `Scope` and is nested under the policy class.
- The first argument is a user. In your controller, Pundit will call the
  `current_user` method to retrieve what to send into this argument.
- The second argument is a scope of some kind on which to perform some kind of
  query. It will usually be an ActiveRecord class or a
  `ActiveRecord::Relation`, but it could be something else entirely.
- Instances of this class respond to the method `resolve`, which should return
  some kind of result which can be iterated over. For ActiveRecord classes,
  this would usually be an `ActiveRecord::Relation`.

You'll probably want to inherit from the application policy scope generated by the
generator, or create your own base class to inherit from:

``` ruby
class PostPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(published: true)
      end
    end
  end

  def update?
    user.admin? or not record.published?
  end
end
```

You can now use this class from your controller via the `policy_scope` method:

``` ruby
def index
  @posts = policy_scope(Post)
end

def show
  @post = policy_scope(Post).find(params[:id])
end
```

Like with the authorize method, you can also override the policy scope class:

``` ruby
def index
  # publication_class => Post
  @publications = policy_scope(publication_class, policy_scope_class: PublicationPolicy::Scope)
end
```

In this case it is a shortcut for doing:

``` ruby
def index
  @publications = PublicationPolicy::Scope.new(current_user, Post).resolve
end
```

You can, and are encouraged to, use this method in views:

``` erb
<% policy_scope(@user.posts).each do |post| %>
  <p><%= link_to post.title, post_path(post) %></p>
<% end %>
```

## Ensuring policies and scopes are used

When you are developing an application with Pundit it can be easy to forget to
authorize some action. People are forgetful after all. Since Pundit encourages
you to add the `authorize` call manually to each controller action, it's really
easy to miss one.

Thankfully, Pundit has a handy feature which reminds you in case you forget.
Pundit tracks whether you have called `authorize` anywhere in your controller
action. Pundit also adds a method to your controllers called
`verify_authorized`. This method will raise an exception if `authorize` has not
yet been called. You should run this method in an `after_action` hook to ensure
that you haven't forgotten to authorize the action. For example:

``` ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized
end
```

Likewise, Pundit also adds `verify_policy_scoped` to your controller. This
will raise an exception similar to `verify_authorized`. However, it tracks
if `policy_scope` is used instead of `authorize`. This is mostly useful for
controller actions like `index` which find collections with a scope and don't
authorize individual instances.

``` ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
end
```

**This verification mechanism only exists to aid you while developing your
application, so you don't forget to call `authorize`. It is not some kind of
failsafe mechanism or authorization mechanism. You should be able to remove
these filters without affecting how your app works in any way.**

Some people have found this feature confusing, while many others
find it extremely helpful. If you fall into the category of people who find it
confusing then you do not need to use it. Pundit will work just fine without
using `verify_authorized` and `verify_policy_scoped`.

### Conditional verification

If you're using `verify_authorized` in your controllers but need to
conditionally bypass verification, you can use `skip_authorization`. For
bypassing `verify_policy_scoped`, use `skip_policy_scope`. These are useful
in circumstances where you don't want to disable verification for the
entire action, but have some cases where you intend to not authorize.

```ruby
def show
  record = Record.find_by(attribute: "value")
  if record.present?
    authorize record
  else
    skip_authorization
  end
end
```

## Manually specifying policy classes

Sometimes you might want to explicitly declare which policy to use for a given
class, instead of letting Pundit infer it. This can be done like so:

``` ruby
class Post
  def self.policy_class
    PostablePolicy
  end
end
```

Alternatively, you can declare an instance method:

``` ruby
class Post
  def policy_class
    PostablePolicy
  end
end
```

## Just plain old Ruby

As you can see, Pundit doesn't do anything you couldn't have easily done
yourself.  It's a very small library, it just provides a few neat helpers.
Together these give you the power of building a well structured, fully working
authorization system without using any special DSLs or funky syntax or
anything.

Remember that all of the policy and scope classes are just plain Ruby classes,
which means you can use the same mechanisms you always use to DRY things up.
Encapsulate a set of permissions into a module and include them in multiple
policies. Use `alias_method` to make some permissions behave the same as
others. Inherit from a base set of permissions. Use metaprogramming if you
really have to.

## Generator

Use the supplied generator to generate policies:

``` sh
rails g pundit:policy post
```

## Closed systems

In many applications, only logged in users are really able to do anything. If
you're building such a system, it can be kind of cumbersome to check that the
user in a policy isn't `nil` for every single permission. Aside from policies,
you can add this check to the base class for scopes.

We suggest that you define a filter that redirects unauthenticated users to the
login page. As a secondary defence, if you've defined an ApplicationPolicy, it
might be a good idea to raise an exception if somehow an unauthenticated user
got through. This way you can fail more gracefully.

``` ruby
class ApplicationPolicy
  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user   = user
    @record = record
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, "must be logged in" unless user
      @user = user
      @scope = scope
    end
  end
end
```

## NilClassPolicy

To support a [null object pattern](https://en.wikipedia.org/wiki/Null_Object_pattern)
you may find that you want to implement a `NilClassPolicy`. This might be useful
where you want to extend your ApplicationPolicy to allow some tolerance of, for
example, associations which might be `nil`.

```ruby
class NilClassPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      raise Pundit::NotDefinedError, "Cannot scope NilClass"
    end
  end

  def show?
    false # Nobody can see nothing
  end
end
```

## Rescuing a denied Authorization in Rails

Pundit raises a `Pundit::NotAuthorizedError` you can
[rescue_from](http://guides.rubyonrails.org/action_controller_overview.html#rescue-from)
in your `ApplicationController`. You can customize the `user_not_authorized`
method in every controller.

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
```

Alternatively, you can globally handle Pundit::NotAuthorizedError's by having rails handle them as a 403 error and serving a 403 error page. Add the following to application.rb:

```config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :forbidden```

## Creating custom error messages

`NotAuthorizedError`s provide information on what query (e.g. `:create?`), what
record (e.g. an instance of `Post`), and what policy (e.g. an instance of
`PostPolicy`) caused the error to be raised.

One way to use these `query`, `record`, and `policy` properties is to connect
them with `I18n` to generate error messages. Here's how you might go about doing
that.

```ruby
class ApplicationController < ActionController::Base
 rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

 private

 def user_not_authorized(exception)
   policy_name = exception.policy.class.to_s.underscore

   flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
   redirect_back(fallback_url: root_path)
 end
end
```

```yaml
en:
 pundit:
   default: 'You cannot perform this action.'
   post_policy:
     update?: 'You cannot edit this post!'
     create?: 'You cannot create posts!'
```

Of course, this is just an example. Pundit is agnostic as to how you implement
your error messaging.

## Manually retrieving policies and scopes

Sometimes you want to retrieve a policy for a record outside the controller or
view. For example when you delegate permissions from one policy to another.

You can easily retrieve policies and scopes like this:

``` ruby
Pundit.policy!(user, post)
Pundit.policy(user, post)

Pundit.policy_scope!(user, Post)
Pundit.policy_scope(user, Post)
```

The bang methods will raise an exception if the policy does not exist, whereas
those without the bang will return nil.

## Customize Pundit user

In some cases your controller might not have access to `current_user`, or your
`current_user` is not the method that should be invoked by Pundit. Simply
define a method in your controller called `pundit_user`.

```ruby
def pundit_user
  User.find_by_other_means
end
```

## Policy Namespacing
In some cases it might be helpful to have multiple policies that serve different contexts for a
resource. A prime example of this is the case where User policies differ from Admin policies. To
authorize with a namespaced policy, pass the namespace into the `authorize` helper in an array:

```ruby
authorize(post)                   # => will look for a PostPolicy
authorize([:admin, post])         # => will look for an Admin::PostPolicy
authorize([:foo, :bar, post])     # => will look for a Foo::Bar::PostPolicy

policy_scope(Post)                # => will look for a PostPolicy::Scope
policy_scope([:admin, Post])      # => will look for an Admin::PostPolicy::Scope
policy_scope([:foo, :bar, Post])  # => will look for a Foo::Bar::PostPolicy::Scope
```

If you are using namespaced policies for something like Admin views, it can be useful to
override the `policy_scope` and `authorize` helpers in your `AdminController` to automatically
apply the namespacing:

```ruby
class AdminController < ApplicationController
  def policy_scope(scope)
    super([:admin, scope])
  end

  def authorize(record, query = nil)
    super([:admin, record], query)
  end
end

class Admin::PostController < AdminController
  def index
    policy_scope(Post)
  end

  def show
    post = authorize Post.find(params[:id])
  end
end
```

## Additional context

Pundit strongly encourages you to model your application in such a way that the
only context you need for authorization is a user object and a domain model that
you want to check authorization for. If you find yourself needing more context than
that, consider whether you are authorizing the right domain model, maybe another
domain model (or a wrapper around multiple domain models) can provide the context
you need.

Pundit does not allow you to pass additional arguments to policies for precisely
this reason.

However, in very rare cases, you might need to authorize based on more context than just
the currently authenticated user. Suppose for example that authorization is dependent
on IP address in addition to the authenticated user. In that case, one option is to
create a special class which wraps up both user and IP and passes it to the policy.

``` ruby
class UserContext
  attr_reader :user, :ip

  def initialize(user, ip)
    @user = user
    @ip   = ip
  end
end

class ApplicationController
  include Pundit::Authorization

  def pundit_user
    UserContext.new(current_user, request.ip)
  end
end
```

## Strong parameters

In Rails,
mass-assignment protection is handled in the controller. With Pundit you can
control which attributes a user has access to update via your policies. You can
set up a `permitted_attributes` method in your policy like this:

```ruby
# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def permitted_attributes
    if user.admin? || user.owner_of?(post)
      [:title, :body, :tag_list]
    else
      [:tag_list]
    end
  end
end
```

You can now retrieve these attributes from the policy:

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def update
    @post = Post.find(params[:id])
    if @post.update(post_params)
      redirect_to @post
    else
      render :edit
    end
  end

  private

  def post_params
    params.require(:post).permit(policy(@post).permitted_attributes)
  end
end
```

However, this is a bit cumbersome, so Pundit provides a convenient helper method:

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def update
    @post = Post.find(params[:id])
    if @post.update(permitted_attributes(@post))
      redirect_to @post
    else
      render :edit
    end
  end
end
```

If you want to permit different attributes based on the current action, you can define a `permitted_attributes_for_#{action}` method on your policy:

```ruby
# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def permitted_attributes_for_create
    [:title, :body]
  end

  def permitted_attributes_for_edit
    [:body]
  end
end
```

If you have defined an action-specific method on your policy for the current action, the `permitted_attributes` helper will call it instead of calling `permitted_attributes` on your controller.

If you need to fetch parameters based on namespaces different from the suggested one, override the below method, in your controller, and return an instance of `ActionController::Parameters`.

```ruby
def pundit_params_for(record)
  params.require(PolicyFinder.new(record).param_key)
end
```

For example:

```ruby
# If you don't want to use require
def pundit_params_for(record)
  params.fetch(PolicyFinder.new(record).param_key, {})
end

# If you are using something like the JSON API spec
def pundit_params_for(_record)
  params.fetch(:data, {}).fetch(:attributes, {})
end
```

## RSpec

### Policy Specs

Pundit includes a mini-DSL for writing expressive tests for your policies in RSpec.
Require `pundit/rspec` in your `spec_helper.rb`:

``` ruby
require "pundit/rspec"
```

Then put your policy specs in `spec/policies`, and make them look somewhat like this:

``` ruby
describe PostPolicy do
  subject { described_class }

  permissions :update?, :edit? do
    it "denies access if post is published" do
      expect(subject).not_to permit(User.new(admin: false), Post.new(published: true))
    end

    it "grants access if post is published and user is an admin" do
      expect(subject).to permit(User.new(admin: true), Post.new(published: true))
    end

    it "grants access if post is unpublished" do
      expect(subject).to permit(User.new(admin: false), Post.new(published: false))
    end
  end
end
```

An alternative approach to Pundit policy specs is scoping them to a user context as outlined in this
[excellent post](http://thunderboltlabs.com/blog/2013/03/27/testing-pundit-policies-with-rspec/) and implemented in the third party [pundit-matchers](https://github.com/chrisalley/pundit-matchers) gem.

### Scope Specs

Pundit does not provide a DSL for testing scopes. Just test it like a regular Ruby class!

### Linting with RuboCop RSpec

When you lint your RSpec spec files with `rubocop-rspec`, it will fail to properly detect RSpec constructs that Pundit defines, `permissions`.
Make sure to use `rubocop-rspec` 2.0 or newer and add the following to your `.rubocop.yml`:

```yaml
inherit_gem:
  pundit: config/rubocop-rspec.yml
```

# External Resources

- [RailsApps Example Application: Pundit and Devise](https://github.com/RailsApps/rails-devise-pundit)
- [Migrating to Pundit from CanCan](http://blog.carbonfive.com/2013/10/21/migrating-to-pundit-from-cancan/)
- [Testing Pundit Policies with RSpec](http://thunderboltlabs.com/blog/2013/03/27/testing-pundit-policies-with-rspec/)
- [Testing Pundit with Minitest](https://github.com/varvet/pundit/issues/204#issuecomment-60166450)
- [Using Pundit outside of a Rails controller](https://github.com/varvet/pundit/pull/136)
- [Straightforward Rails Authorization with Pundit](http://www.sitepoint.com/straightforward-rails-authorization-with-pundit/)

## Other implementations

- [Flask-Pundit](https://github.com/anurag90x/flask-pundit) (Python) is a [Flask](http://flask.pocoo.org/) extension "heavily inspired by" Pundit

# License

Licensed under the MIT license, see the separate LICENSE.txt file.

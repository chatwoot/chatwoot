# Sift

[![Build Status](https://travis-ci.org/procore/sift.svg?branch=master)](https://travis-ci.org/procore/sift)

A tool to build your own filters and sorts with Rails and Active Record!

## Developer Usage

Include Sift in your controllers, and define some filters.

```ruby
class PostsController < ApplicationController
  include Sift

  filter_on :title, type: :string

  def index
    render json: filtrate(Post.all)
  end
end
```

This will allow users to pass `?filters[title]=foo` and get the `Post`s with the title `foo`.

Sift will also handle rendering errors using the standard rails errors structure. You can add this to your controller by adding,

```ruby
before_action :render_filter_errors, unless: :filters_valid?

def render_filter_errors
  render json: { errors: filter_errors }, status: :bad_request && return
end
```

to your controller.

These errors are based on the type that you told sift your param was.

### Filter Types

Every filter must have a type, so that Sift knows what to do with it. The current valid filter types are:

- int - Filter on an integer column
- decimal - Filter on a decimal column
- boolean - Filter on a boolean column
- string - Filter on a string column
- text - Filter on a text column
- date - Filter on a date column
- time - Filter on a time column
- datetime - Filter on a datetime column
- scope - Filter on an ActiveRecord scope
- jsonb - Filter on a jsonb column (supported only in PostgreSQL)

### Filter on Scopes

Just as your filter values are used to scope queries on a column, values you
pass to a scope filter will be used as arguments to that scope. For example:

```ruby
class Post < ActiveRecord::Base
  scope :with_body, ->(text) { where(body: text) }
end

class PostsController < ApplicationController
  include Sift

  filter_on :with_body, type: :scope

  def index
    render json: filtrate(Post.all)
  end
end
```

Passing `?filters[with_body]=my_text` will call the `with_body` scope with
`my_text` as the argument.

Scopes that accept no arguments are currently not supported.

#### Accessing Params with Filter Scopes

Filters with `type: :scope` have access to the params hash by passing in the desired keys to the `scope_params`. The keys passed in will be returned as a hash with their associated values.

```ruby
class Post < ActiveRecord::Base
  scope :user_posts_on_date, ->(date, options) {
    where(user_id: options[:user_id], blog_id: options[:blog_id], date: date)
  }
end

class UsersController < ApplicationController
  include Sift

  filter_on :user_posts_on_date, type: :scope, scope_params: [:user_id, :blog_id]

  def show
    render json: filtrate(Post.all)
  end
end
```

Passing `?filters[user_posts_on_date]=10/12/20` will call the `user_posts_on_date` scope with
`10/12/20` as the the first argument, and will grab the `user_id` and `blog_id` out of the params and pass them as a hash, as the second argument.

### Renaming Filter Params

A filter param can have a different field name than the column or scope. Use `internal_name` with the correct name of the column or scope.

```ruby
class PostsController < ApplicationController
  include Sift

  filter_on :post_id, type: :int, internal_name: :id

end
```

### Filter on Ranges

Some parameter types support ranges. Ranges are expected to be a string with the bounding values separated by `...`

For example `?filters[price]=3...50` would return records with a price between 3 and 50.

The following types support ranges

- int
- decimal
- boolean
- date
- time
- datetime

### Mutating Filters

Filters can be mutated before the filter is applied using the `tap` argument. This is useful, for example, if you need to adjust the time zone of a `datetime` range filter.

```ruby

class PostsController < ApplicationController
  include Sift

  filter_on :expiration, type: :datetime, tap: ->(value, params) {
    value.split("...").
      map do |str|
        str.to_date.in_time_zone(LOCAL_TIME_ZONE)
      end.
      join("...")
  }
end
```

### Filter on jsonb column

Usually JSONB columns stores values as an Array or an Object (key-value), in both cases the parameter needs to be sent in a JSON format

**Array**

It should be sent an array in the URL Query parameters

- `?filters[metadata]=[1,2]`

**key-value**

It can be passed one or more Key values:

- `?filters[metadata]={"data_1":"test"}`
- `?filters[metadata]={"data_1":"test","data_2":"[1,2]"}`

When the value is an array, it will filter records with those values or more, for example:

- `?filters[metadata]={"data_2":"[1,2]"}`

Will return records with next values stored in the JSONB column `metadata`:

```ruby
{ data_2: 1 }
{ data_2: 2 }
{ data_2: [1] }
{ data_2: [2] }
{ data_2: [1,2] }
{ data_2: [1,2,3] }
```

When the `null` value is included in the array, it will return also all the records without any value in that property, for example:

- `?filters[metadata]={"data_2":"[false,null]"}`

Will return records with next values stored in the JSONB column `metadata`:

```ruby
{ data_2: null }
{ data_2: false }
{ data_2: [false] }
{ data_1: {another: 'information'} } # When the JSONB key "data_2" is not set.
```

### Filter on JSON Array

`int` type filters support sending the values as an array in the URL Query parameters. For example `?filters[id]=[1,2]`. This is a way to keep payloads smaller for GET requests. When URI encoded this will become `filters%5Bid%5D=%5B1,2%5D` which is much smaller the standard format of `filters%5Bid%5D%5B%5D=1&&filters%5Bid%5D%5B%5D=2`.

On the server side, the params will be received as:

```ruby
# JSON array encoded result
"filters"=>{"id"=>"[1,2]"}

# standard array format
"filters"=>{"id"=>["1", "2"]}
```

Note that this feature cannot currently be wrapped in an array and should not be used in combination with sending array parameters individually.

- `?filters[id][]=[1,2]` => invalid
- `?filters[id][]=[1,2]&filters[id][]=3` => invalid
- `?filters[id]=[1,2]&filters[id]=3` => valid but only 3 is passed through to the server
- `?filters[id]=[1,2]` => valid

#### A note on encoding for JSON Array feature

JSON arrays contain the reserved characters "`,`" and "`[`" and "`]`". When encoding a JSON array in the URL there are two different ways to handle the encoding. Both ways are supported by Rails.
For example, lets look at the following filter with a JSON array `?filters[id]=[1,2]`:

- `?filters%5Bid%5D=%5B1,2%5D`
- `?filters%5Bid%5D%3D%5B1%2C2%5D`

In both cases Rails will correctly decode to the expected result of

```ruby
{ "filters" => { "id" => "[1,2]" } }
```

### Sort Types

Every sort must have a type, so that Sift knows what to do with it. The current valid sort types are:

- int - Sort on an integer column
- decimal - Sort on a decimal column
- string - Sort on a string column
- text - Sort on a text column
- date - Sort on a date column
- time - Sort on a time column
- datetime - Sort on a datetime column
- scope - Sort on an ActiveRecord scope

### Sort on Scopes

Just as your sort values are used to scope queries on a column, values you
pass to a scope sort will be used as arguments to that scope. For example:

```ruby
class Post < ActiveRecord::Base
  scope :order_on_body_no_params, -> { order(body: :asc) }
  scope :order_on_body, ->(direction) { order(body: direction) }
  scope :order_on_body_then_id, ->(body_direction, id_direction) { order(body: body_direction).order(id: id_direction) }
end

class PostsController < ApplicationController
  include Sift

  sort_on :order_by_body_ascending, internal_name: :order_on_body_no_params, type: :scope
  sort_on :order_by_body, internal_name: :order_on_body, type: :scope, scope_params: [:direction]
  sort_on :order_by_body_then_id, internal_name: :order_on_body_then_id, type: :scope, scope_params: [:direction, :asc]


  def index
    render json: filtrate(Post.all)
  end
end
```

`scope_params` takes an order-specific array of the scope's arguments. Passing in the param :direction allows the consumer to choose which direction to sort in (ex. `-order_by_body` will sort `:desc` while `order_by_body` will sort `:asc`)

Passing `?sort=-order_by_body` will call the `order_on_body` scope with
`:desc` as the argument. The direction is the only argument that the consumer has control over.
Passing `?sort=-order_by_body_then_id` will call the `order_on_body_then_id` scope where the `body_direction` is `:desc`, and the `id_direction` is `:asc`. Note: in this example the user has no control over id_direction. To demonstrate:
Passing `?sort=order_by_body_then_id` will call the `order_on_body_then_id` scope where the `body_direction` this time is `:asc`, but the `id_direction` remains `:asc`.

Scopes that accept no arguments are currently supported, but you should note that the user has no say in which direction it will sort on.

`scope_params` can also accept symbols that are keys in the `params` hash. The value will be fetched and passed on as an argument to the scope.

## Consumer Usage

Filter:
`?filters[<field_name>]=<value>`

Filters are translated to Active Record `where`s and are chained together. The order they are applied is not guarenteed.

Sort:
`?sort=-published_at,position`

Sort is translated to Active Record `order` The sorts are applied in the order they are passed by the client.
the `-` symbol means to sort in `desc` order. By default, keys are sorted in `asc` order.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'procore-sift'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install procore-sift
```

## Without Rails

We have some future plans to remove the rails dependency so that other frameworks such as Sinatra could leverage this gem.

## Contributing

Installing gems before running tests:

```bash
$ bundle exec appraisal install
```

Running tests:

```bash
$ bundle exec appraisal rake test
```

## Publishing

Publishing is done use the `gem` commandline tool. You must have permissions to publish a new version. Users with permissions can be seen here https://rubygems.org/gems/procore-sift.

When a bump is desired, the gemspec should have the version number bumped and merged into master.

Step 1: build the new version
`gem build sift.gemspec`

```
  Successfully built RubyGem
  Name: procore-sift
  Version: 0.14.0
  File: procore-sift-0.14.0.gem
```

Step2: Push the updated build
`gem push procore-sift-0.14.0.gem`

```
Pushing gem to https://rubygems.org...
Successfully registered gem: procore-sift (0.14.0)
```

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

## About Procore

<img
  src="https://www.procore.com/images/procore_logo.png"
  alt="Procore Logo"
  width="250px"
/>

The Procore Gem is maintained by Procore Technologies.

Procore - building the software that builds the world.

Learn more about the #1 most widely used construction management software at
[procore.com](https://www.procore.com/)

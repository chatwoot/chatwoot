[![Gem Version](https://badge.fury.io/rb/attr_extras.svg)](https://badge.fury.io/rb/attr_extras)
[![Ruby CI](https://github.com/barsoom/attr_extras/actions/workflows/ci.yml/badge.svg)](https://github.com/barsoom/attr_extras/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/barsoom/attr_extras/badges/gpa.svg)](https://codeclimate.com/github/barsoom/attr_extras)

# attr\_extras

Takes some boilerplate out of Ruby, lowering the barrier to extracting small focused classes, without [the downsides of using `Struct`](http://thepugautomatic.com/2013/08/struct-inheritance-is-overused/).

Provides lower-level methods like `attr_private` and `attr_value` that nicely complement Ruby's built-in `attr_accessor`, `attr_reader` and `attr_writer`.

Also higher-level ones like `pattr_initialize` (or `attr_private_initialize`) and `method_object` to really cut down on the boilerplate.

Instead of

``` ruby
class InvoicePolicy
  def initialize(invoice, company:)
    @invoice = invoice
    @company = company
  end

  def payable?
    some_logic(invoice, company)
  end

  private

  attr_reader :invoice, :company
end
```

you can just do

``` ruby
class InvoiceBuilder
  pattr_initialize :invoice, [:company!]

  def payable?
    some_logic(invoice, company)
  end
end
```

And instead of

``` ruby
class PayInvoice
  def self.call(invoice, amount)
    new(invoice, amount).call
  end

  def initialize(invoice, amount)
    @invoice = invoice
    @amount = amount
  end

  def call
    PaymentGateway.charge(invoice.id, amount_in_cents)
  end

  private

  def amount_in_cents
    amount * 100
  end

  attr_reader :invoice, :amount
end
```

you can just do

``` ruby
class PayInvoice
  method_object :invoice, :amount

  def call
    PaymentGateway.charge(invoice.id, amount_in_cents)
  end

  private

  def amount_in_cents
    amount * 100
  end
end
```

Supports positional arguments as well as optional and required keyword arguments.

Also provides conveniences for creating value objects, method objects, query methods and abstract methods.


## Usage

* [`attr_initialize`](#attr_initialize)
* [`attr_private`](#attr_private)
* [`attr_value`](#attr_value)
* [`pattr_initialize`](#pattr_initialize) / [`attr_private_initialize`](#attr_private_initialize)
* [`vattr_initialize`](#vattr_initialize) / [`attr_value_initialize`](#attr_value_initialize)
* [`rattr_initialize`](#rattr_initialize) / [`attr_reader_initialize`](#attr_reader_initialize)
* [`aattr_initialize`](#aattr_initialize) / [`attr_accessor_initialize`](#attr_accessor_initialize)
* [`static_facade`](#static_facade)
* [`method_object`](#method_object)
* [`attr_implement`](#attr_implement)
* [`cattr_implement`](#cattr_implement)
* [`attr_query`](#attr_query)
* [`attr_id_query`](#attr_id_query)


### `attr_initialize`

`attr_initialize :foo, :bar` defines an initializer that takes two arguments and assigns `@foo` and `@bar`.

`attr_initialize :foo, [:bar, :baz!]` defines an initializer that takes one regular argument, assigning `@foo`, and two keyword arguments, assigning `@bar` (optional) and `@baz` (required).

`attr_initialize [:bar, :baz!]` defines an initializer that takes two keyword arguments, assigning `@bar` (optional) and `@baz` (required).

If you pass unknown keyword arguments, you will get an `ArgumentError`.
If you don't pass required arguments and don't define default value for them, you will get a `KeyError`.

`attr_initialize` can also accept a block which will be invoked after initialization. This is useful for e.g. initializing private data as necessary.

#### Default values

Keyword arguments can have default values:

`attr_initialize [:bar, baz: "default value"]` defines an initializer that takes two keyword arguments, assigning `@bar` (optional) and `@baz` (optional with default value `"default value"`).

Note that default values are evaluated *when the class is loaded* and not on every instantition. So `attr_initialize [time: Time.now]` might not do what you expect.

You can always use regular Ruby methods to achieve this:

```
class Foo
  attr_initialize [:time]

  private

  def time
    @time || Time.now
  end
end
```

Or just use a regular initializer with default values.


### `attr_private`

`attr_private :foo, :bar` defines private readers for `@foo` and `@bar`.


### `attr_value`

`attr_value :foo, :bar` defines public readers for `@foo` and `@bar` and also defines object equality: two value objects of the same class with the same values will be considered equal (with `==` and `eql?`, in `Set`s, as `Hash` keys etc).

It does not define writers, because [value objects](http://en.wikipedia.org/wiki/Value_object) are typically immutable.


### `pattr_initialize`
### `attr_private_initialize`

`pattr_initialize :foo, :bar` defines both initializer and private readers. Shortcut for:

``` ruby
attr_initialize :foo, :bar
attr_private :foo, :bar
```

`pattr_initialize` is aliased as `attr_private_initialize` if you prefer a longer but clearer name.

Example:

``` ruby
class Item
  pattr_initialize :name, :price

  def price_with_vat
    price * 1.25
  end
end

Item.new("Pug", 100).price_with_vat  # => 125.0
```

[The `attr_initialize` notation](#attr_initialize) for keyword arguments is also supported: `pattr_initialize :foo, [:bar, :baz!]`

### `vattr_initialize`
### `attr_value_initialize`

`vattr_initialize :foo, :bar` defines initializer, public readers and [value object identity](#attr_value). Shortcut for:

``` ruby
attr_initialize :foo, :bar
attr_value :foo, :bar
```

`vattr_initialize` is aliased as `attr_value_initialize` if you prefer a longer but clearer name.

Example:

``` ruby
class Country
  vattr_initialize :code
end

Country.new("SE") == Country.new("SE")  # => true
Country.new("SE").code  # => "SE"
```

[The `attr_initialize` notation](#attr_initialize) for keyword arguments is also supported: `vattr_initialize :foo, [:bar, :baz!]`


### `rattr_initialize`
### `attr_reader_initialize`

`rattr_initialize :foo, :bar` defines both initializer and public readers. Shortcut for:

``` ruby
attr_initialize :foo, :bar
attr_reader :foo, :bar
```

`rattr_initialize` is aliased as `attr_reader_initialize` if you prefer a longer but clearer name.

Example:

``` ruby
class PublishBook
  rattr_initialize :book_name, :publisher_backend

  def call
    publisher_backend.publish book_name
  end
end

service = PublishBook.new("A Novel", publisher)
service.book_name  # => "A Novel"
```

[The `attr_initialize` notation](#attr_initialize) for keyword arguments is also supported: `rattr_initialize :foo, [:bar, :baz!]`

### `aattr_initialize`
### `attr_accessor_initialize`

`aattr_initialize :foo, :bar` defines an initializer, public readers, and public writers. It's a shortcut for:

``` ruby
attr_initialize :foo, :bar
attr_accessor :foo, :bar
```

`aattr_initialize` is aliased as `attr_accessor_initialize`, if you prefer a longer but clearer name.

Example:

``` ruby
class Client
  aattr_initialize :username, :access_token
end

client = Client.new("barsoom", "SECRET")
client.username # => "barsoom"

client.access_token = "NEW_SECRET"
client.access_token # => "NEW_SECRET"
```

[The `attr_initialize` notation](#attr_initialize) for keyword arguments and blocks is also supported.

### `static_facade`

`static_facade :allow?, :user` defines an `.allow?` class method that delegates to an instance method by the same name, having first provided `user` as a private reader.

This is handy when a class-method API makes sense but you still want [the refactorability of instance methods](http://blog.codeclimate.com/blog/2012/11/14/why-ruby-class-methods-resist-refactoring/).

Example:

``` ruby
class PublishingPolicy
  static_facade :allow?, :user

  def allow?
    user.admin? && complicated_extracted_method
  end

  private

  def complicated_extracted_method
    # …
  end
end

PublishingPolicy.allow?(user)
```

`static_facade :allow?, :user` is a shortcut for

``` ruby
pattr_initialize :user

def self.allow?(user)
  new(user).allow?
end
```

[The `attr_initialize` notation](#attr_initialize) for keyword arguments is also supported: `static_facade :allow?, :user, [:user_agent, :ip!]`

You don't have to specify arguments/readers if you don't want them: just `static_facade :tuesday?` is also valid.

You can specify multiple method names as long as they can share the same initializer arguments: `static_facade [:allow?, :deny?], :user, [:user_agent, :ip!]`

Any block given to the class method will be passed on to the instance method.

"Static façade" is the least bad name for this pattern we've come up with. Suggestions are welcome.


### `method_object`

*NOTE: v4.0.0 made a breaking change! [`static_facade`](#static_facade) does exactly what `method_object` used to do; the new `method_object` no longer accepts a method name argument.*

`method_object :foo` defines a `.call` class method that delegates to an instance method by the same name, having first provided `foo` as a private reader.

This is a special case of [`static_facade`](#static_facade) for when you want a [Method Object](http://refactoring.com/catalog/replaceMethodWithMethodObject.html), and the class name itself will communicate the action it performs.

Example:

``` ruby
class CalculatePrice
  method_object :order

  def call
    total * factor
  end

  private

  def total
    order.items.map(&:price).inject(:+)
  end

  def factor
    1 + rand
  end
end

class Order
  def price
    CalculatePrice.call(self)
  end
end
```

You could even do `CalculatePrice.(self)` if you like, since we're using the [`call` convention](http://www.ruby-doc.org/core-2.2.0/Proc.html#method-i-call).

`method_object :foo` is a shortcut for

``` ruby
static_facade :call, :foo
```

which is a shortcut for

``` ruby
pattr_initialize :foo

def self.call(foo)
  new(foo).call
end
```

[The `attr_initialize` notation](#attr_initialize) for keyword arguments is also supported: `method_object :foo, [:bar, :baz!]`

You don't have to specify arguments/readers if you don't want them: just `method_object` is also valid.

Any block given to the class method will be passed on to the instance method.


### `attr_implement`

`attr_implement :foo, :bar` defines nullary (0-argument) methods `foo` and `bar` that raise e.g. `"Implement a 'foo()' method"`.

`attr_implement :foo, [:name, :age]` will define a binary (2-argument) method `foo` that raises `"Implement a 'foo(name, age)' method"`.

This is suitable for [abstract methods](http://en.wikipedia.org/wiki/Abstract_method#Abstract_methods) in base classes, e.g. when using the [template method pattern](http://en.wikipedia.org/wiki/Template_method_pattern).

It's more or less a shortcut for

``` ruby
def my_method
  raise "Implement me in a subclass!"
end
```

though it is shorter, more declarative, gives you a clear message and handles edge cases you might not have thought about (see tests).

Note that you can also use this with modules, to effectively mix in interfaces:

``` ruby
module Bookable
  attr_implement :book, [:bookable]
  attr_implement :booked?
end

class Invoice
  include Bookable
end

class Payment
  include Bookable
end
```


### `cattr_implement`

Like [`attr_implement`](#attr_implement) but for class methods.

Example:

``` ruby
class TransportOrder
  cattr_implement :must_be_tracked?
end
```


### `attr_query`

`attr_query :foo?, :bar?` defines query methods like `foo?`, which is true if (and only if) `foo` is truthy.


### `attr_id_query`

`attr_id_query :foo?, :bar?` defines query methods like `foo?`, which is true if (and only if) `foo_id` is truthy. Goes well with Active Record.


## Explicit mode

By default, attr\_extras will add methods to every class and module.

This is not ideal if you're using attr\_extras in a library: those who depend on your library will get those methods as well.

It's also not obvious where the methods come from. You can be more explicit about it, and restrict where the methods are added, like this:

``` ruby
require "attr_extras/explicit"

class MyLib
  extend AttrExtras.mixin

  pattr_initialize :now_this_class_can_use_attr_extras
end
```

Crucially, you need to `require "attr_extras/explicit"` *instead of* `require "attr_extras"`. Some frameworks, like Ruby on Rails, may automatically require everything in your `Gemfile`. You can avoid that with `gem "attr_extras", require: "attr_extras/explicit"`.

In explicit mode, you need to call `extend AttrExtras.mixin` *in every class or module* that wants the attr\_extras methods.


## Philosophy

Findability is a core value.
Hence the long name `attr_initialize`, so you see it when scanning for the initializer;
and the enforced questionmarks with `attr_id_query :foo?`, so you can search for that method.


## Q & A


### Why not use `Struct` instead of `pattr_initialize`?

See: ["Struct inheritance is overused"](http://thepugautomatic.com/2013/08/struct-inheritance-is-overused/)


### Why not use `private; attr_reader :foo` instead of `attr_private :foo`?

Other than being more to type, declaring `attr_reader` after `private` will actually give you a warning (deserved or not) if you run Ruby with warnings turned on.

If you don't want the dependency on `attr_extras`, you can get rid of the warnings with `attr_reader :foo; private :foo`. Or just define a regular private method.

### Can I use attr\_extras in `BasicObject`s?

No, sorry. It depends on various methods that `BasicObject`s don't have. Use a regular `Object` or make do without attr\_extras.


## Installation

Add this line to your application's `Gemfile`:

    gem "attr_extras"

And then execute:

    bundle

Or install it yourself as:

    gem install attr_extras


## Running the tests

Run them with:

    rake

Or to see warnings (try not to have any):

    RUBYOPT=-w rake

You can run an individual test using the [m](https://github.com/qrush/m) gem:

    m spec/attr_extras/attr_initialize_spec.rb:48

The tests are intentionally split into two test suites for reasons described in `Rakefile`.


## License

[MIT](LICENSE.txt)

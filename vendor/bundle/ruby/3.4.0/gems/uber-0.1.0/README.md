# Uber

_Gem-authoring tools like class method inheritance in modules, dynamic options and more._

## Installation

[![Gem Version](https://badge.fury.io/rb/uber.svg)](http://badge.fury.io/rb/uber)

Add this line to your application's Gemfile:

```ruby
gem 'uber'
```

Uber runs with Ruby >= 1.9.3.

# Inheritable Class Attributes

If you want inherited class attributes, this is for you.
This is a mandatory mechanism for creating DSLs.

```ruby
require 'uber/inheritable_attr'

class Song
  extend Uber::InheritableAttr

  inheritable_attr :properties
  self.properties = [:title, :track] # initialize it before using it.
end
```

Note that you have to initialize your class attribute with whatever you want - usually a hash or an array.

```ruby
Song.properties #=> [:title, :track]
```

A subclass of `Song` will have a `clone`d `properties` class attribute.

```ruby
class Hit < Song
end

Hit.properties #=> [:title, :track]
```

The cool thing about the inheritance is: you can work on the inherited attribute without any restrictions. It is a _copy_ of the original.

```ruby
Hit.properties << :number

Hit.properties  #=> [:title, :track, :number]
Song.properties #=> [:title, :track]
```

It's similar to ActiveSupport's `class_attribute` but with a simpler implementation.
It is less dangerous. There are no restrictions for modifying the attribute. [compared to `class_attribute`](http://apidock.com/rails/v4.0.2/Class/class_attribute).

## Uncloneable Values

`::inheritable_attr` will `clone` values to copy them to subclasses. Uber won't attempt to clone `Symbol`, `nil`, `true` and `false` per default.

If you assign any other unclonable value you need to tell Uber that.

```ruby
class Song
  extend Uber::InheritableAttr
  inheritable_attr :properties, clone: false
```

This won't `clone` but simply pass the value on to the subclass.


# Dynamic Options

Implements the pattern of defining configuration options and dynamically evaluating them at run-time.

Usually DSL methods accept a number of options that can either be static values, symbolized instance method names, or blocks (lambdas/Procs).

Here's an example from Cells.

```ruby
cache :show, tags: lambda { Tag.last }, expires_in: 5.mins, ttl: :time_to_live
```

Usually, when processing these options, you'd have to check every option for its type, evaluate the `tags:` lambda in a particular context, call the `#time_to_live` instance method, etc.

This is abstracted in `Uber::Options` and could be implemented like this.

```ruby
require 'uber/options'

options = Uber::Options.new(tags:       lambda { Tag.last },
                            expires_in: 5.mins,
                            ttl:        :time_to_live)
```

Just initialize `Options` with your actual options hash. While this usually happens on class level at compile-time, evaluating the hash happens at run-time.

```ruby
class User < ActiveRecord::Base # this could be any Ruby class.
  # .. lots of code

  def time_to_live(*args)
    "n/a"
  end
end

user = User.find(1)

options.evaluate(user, *args) #=> {tags: "hot", expires_in: 300, ttl: "n/a"}
```

## Evaluating Dynamic Options

To evaluate the options to a real hash, the following happens:

* The `tags:` lambda is executed in `user` context (using `instance_exec`). This allows accessing instance variables or calling instance methods.
* Nothing is done with `expires_in`'s value, it is static.
* `user.time_to_live?` is called as the symbol `:time_to_live` indicates that this is an instance method.

The default behaviour is to treat `Proc`s, lambdas and symbolized `:method` names as dynamic options, everything else is considered static. Optional arguments from the `evaluate` call are passed in either as block or method arguments for dynamic options.

This is a pattern well-known from Rails and other frameworks.

## Uber::Callable

A third way of providing a dynamic option is using a "callable" object. This saves you the unreadable lambda syntax and gives you more flexibility.

```ruby
require 'uber/callable'
class Tags
  include Uber::Callable

  def call(context, *args)
    [:comment]
  end
end
```

By including `Uber::Callable`, uber will invoke the `#call` method on the specified object.

Note how you simply pass an instance of the callable object into the hash instead of a lambda.

```ruby
options = Uber::Options.new(tags: Tags.new)
```

## Option

`Uber::Option` implements the pattern of taking an option, such as a proc, instance method name, or static value, and evaluate it at runtime without knowing the option's implementation.

Creating `Option` instances via `::[]` usually happens on class-level in DSL methods.

```ruby
with_proc    = Uber::Option[ ->(options) { "proc: #{options.inspect}" } ]
with_static  = Uber::Option[ "Static value" ]
with_method  = Uber::Option[ :name_of_method ]

def name_of_method(options)
  "method: #{options.inspect}"
end
```

Use `#call` to evaluate the options at runtime.

```ruby
with_proc.(1, 2)         #=> "proc: [1, 2]"
with_static.(1, 2)       #=> "Static value"   # arguments are ignored
with_method.(self, 1, 2) #=> "method: [1, 2]" # first arg is context
```

It's also possible to evaluate a callable object. It has to be marked with `Uber::Callable` beforehand.

```ruby
class MyCallable
  include Uber::Callable

  def call(context, *args)
    "callable: #{args.inspect}, #{context}"
  end
end

with_callable = Uber::Option[ MyCallable.new ]
```

The context is passed as first argument.

```ruby
with_callable.(Object, 1, 2) #=> "callable: [1, 2] Object"
```

You can also make blocks being `instance_exec`ed on the context, giving a unique API to all option types.

```ruby
with_instance_proc  = Uber::Option[ ->(options) { "proc: #{options.inspect} #{self}" }, instance_exec: true ]
```

The first argument now becomes the context, exactly the way it works for the method and callable type.

```ruby
with_instance_proc.(Object, 1, 2) #=> "proc [1, 2] Object"
```


# Delegates

Using `::delegates` works exactly like the `Forwardable` module in Ruby, with one bonus: It creates the accessors in a module, allowing you to override and call `super` in a user module or class.

```ruby
require 'uber/delegates'

class SongDecorator
  def initialize(song)
    @song = song
  end
  attr_reader :song

  extend Uber::Delegates

  delegates :song, :title, :id # delegate :title and :id to #song.

  def title
    super.downcase # this calls the original delegate #title.
  end
end
```

This creates readers `#title` and `#id` which are delegated to `#song`.

```ruby
song = SongDecorator.new(Song.create(id: 1, title: "HELLOWEEN!"))

song.id #=> 1
song.title #=> "helloween!"
```

Note how `#title` calls the original title and then downcases the string.

# Builder

Builders are good for polymorphically creating objects without having to know where that happens. You define a builder with conditions in one class, and that class takes care of creating the actual desired class.

## Declarative Interface

Include `Uber::Builder` to leverage the `::builds` method for adding builders, and `::build!` to run those builders in a given context and with arbitrary options.


```ruby
require "uber/builder"

class User
  include Uber::Builder

  builds do |options|
    Admin if params[:admin]
  end
end

class Admin
end
```

Note that you can call `builds` as many times as you want per class.

Run the builders using `::build!`.

```ruby
User.build!(User, {})              #=> User
User.build!(User, { admin: true }) #=> Admin
```
The first argument is the context in which the builder blocks will be executed. This is also the default return value if all builders returned a falsey value.

All following arguments will be passed straight through to the procs.

Your API should communicate `User` as the only public class, since the builder hides details about computing the concrete class.

### Builder: Procs

You may also use procs instead of blocks.

```ruby
class User
  include Uber::Builder

  builds ->(options) do
    return SignedIn if params[:current_user]
    return Admin    if params[:admin]
    Anonymous
  end
end
```

Note that this allows `return`s in the block.

## Builder: Direct API

In case you don't want the `builds` DSL, you can instantiate a `Builders` object yourself and add builders to it using `#<<`.

```ruby
MyBuilders = Uber::Builder::Builders.new
MyBuilders << ->(options) do
  return Admin if options[:admin]
end
```

Note that you can call `Builders#<<` multiple times per instance.

Invoke the builder using `#call`.

```ruby
MyBuilders.call(User, {})              #=> User
MyBuilders.call(User, { admin: true }) #=> Admin
```

Again, the first object is the context/default return value, all other arguments are passed to the builder procs.

## Builder: Contexts

Every proc is `instance_exec`ed in the context you pass into `build!` (or `call`), allowing you to define generic, shareable builders.

```ruby
MyBuilders = Uber::Builder::Builders.new
MyBuilders << ->(options) do
  return self::Admin if options[:admin] # note the self:: !
end

class User
  class Admin
  end
end

class Instructor
  class Admin
  end
end
```

Now, depending on the context class, the builder will return different classes.

```ruby
MyBuilders.call(User, {})              #=> User
MyBuilders.call(User, { admin: true }) #=> User::Admin
MyBuilders.call(Instructor, {})              #=> Instructor
MyBuilders.call(Instructor, { admin: true }) #=> Instructor::Admin
```

Don't forget the `self::` when writing generic builders, and write tests.

# License

Copyright (c) 2014 by Nick Sutterer <apotonick@gmail.com>

Uber is released under the [MIT License](http://www.opensource.org/licenses/MIT).

# Declarative

_DSL for nested schemas._

[![Gem Version](https://badge.fury.io/rb/declarative.svg)](http://badge.fury.io/rb/declarative)

# Overview

Declarative allows _declaring_ nested schemas.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'declarative'
```

## Declarative::Schema

Include this into a class or module to allow defining nested schemas using the popular `::property` DSL.

Normally, an abstract base class will define essential configuration.

```ruby
class Model
 extend Declarative::Schema

  def self.default_nested_class
    Model
  end
end
```

Concrete schema-users simply derive from the base class.

```ruby
class Song < Model
  property :id

  property :artist do
    property :id
    property :name
  end
end
```

This won't do anything but populate the `::definitions` graph.

```ruby
Song.definitions #=>

<Definition "id">
<Definition "artist" nested=..>
  <Definition "id">
  <Definition "name">
```

The nested schema will be a subclass of `Model`.

```ruby
Song.definitions.get(:artist) #=> <Anonymous:Model definitions=..>
```

## Overriding Nested Building

When declaring nested schemas, per default, Declarative will use its own `Schema::NestedBuilder` to create the nested schema composer.

Override `::nested_builder` to define your own way of doing that.

```ruby
class Model
  extend Declarative::Schema

  def self.default_nested_class
    Model
  end

  def self.nested_builder
    ->(options) do
      Class.new(Model) do
        class_eval &options[:_block] # executes `property :name` etc. on nested, fresh class.
      end
    end
  end
end
```

## Features

You can automatically include modules into all nested schemas by using `::feature`.

```ruby
class Model
  extend Declarative::Schema
  feature Bla
```

## Defaults

```ruby
class Model
  extend Declarative::Schema
  defaults visible: true
```

## Copyright

* Copyright (c) 2015 Nick Sutterer <apotonick@gmail.com>

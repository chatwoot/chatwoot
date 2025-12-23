# Trailblazer::Option

_Dynamic options to evaluate at runtime._

`Trailblazer::Option` is the one of the core concept behind `traiblazer-operation`'s [step API](https://trailblazer.to/2.1/docs/activity.html#activity-wiring-api), `reform`'s [populator API](https://trailblazer.to/2.1/docs/reform.html#reform-populators) etc. It makes us possible to accept any kind of callable objects at compile time and execute them at runtime.

```ruby
class Song::Create < Trailblazer::Operation
  step Authorize				# Module callable
  step :model					# Method callable
  step ->(ctx, model:, **) { puts model }	# Proc callable
end
```

This gem is a replacement over [declarative-option](https://github.com/apotonick/declarative-option) and has been extracted out from [trailblazer-context](https://github.com/trailblazer/trailblazer-context) by identifying common callable patterns.

# Option

`Trailblazer::Option()` accepts `:symbol`, `lambda` and any other type of `callable` as an argument. It will be wrapped accordingly to make an executable, so you can call the value at runtime to evaluate it.

When passing in a `:symbol`, this will be treated as a method that's called on the given `exec_context`.

```ruby
option = Trailblazer::Option(:object_id)
option.(exec_context: Object.new) #=> 2354383
```

Same with objects responding to `.call` or `#call` method.

```ruby
class CallMe
  def self.call(*args, message:, **options)
    message
  end
end

option = Trailblazer::Option(CallMe)
option.(*args, keyword_arguments: { message: "hello!" }, exec_context: nil) => "hello!"
```

Notice the usage of `keyword_arguments` while calling an `Option`. This is because keyword arguments needs to be forwarded separately in order for them to be [compatible](https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/) with ruby 2.7+.

And of course, passing lambdas. They gets executed within given `exec_context` when set.

```ruby
option = Trailblazer::Option( -> { object_id } )
option.(exec_context: Object.new) #=> 1234567
```

# Installation

Add this line to your application's Gemfile:

```ruby
gem 'trailblazer-option'
```

# Copyright

Copyright (c) 2017-2021 TRAILBLAZER GmbH.

`trailblazer-option` is released under the [MIT License](http://www.opensource.org/licenses/MIT).

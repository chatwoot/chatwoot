# frozen_string_literal: true

module RuboCop
  # Similar to `Forwardable#def_delegators`, but simpler & faster
  module SimpleForwardable
    def def_delegators(accessor, *methods)
      methods.each do |method|
        if method.end_with?('=') && method.to_s != '[]='
          # Defining a delegator for `foo=` can't use `foo=(...)` because it is a
          # syntax error. Fall back to doing a slower `public_send` instead.
          # TODO: Use foo(method, ...) when Ruby 3.1 is required.
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{method}(*args, **kwargs, &blk)                         # def example=(*args, **kwargs, &blk)
              #{accessor}.public_send(:#{method}, *args, **kwargs, &blk) #   foo.public_send(:example=, *args, **kwargs, &blk)
            end                                                          # end
          RUBY
        else
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{method}(...)           # def example(...)
              #{accessor}.#{method}(...) #   foo.example(...)
            end                          # end
          RUBY
        end
      end
    end
  end
end

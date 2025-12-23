module RSpec
  module Matchers
    # Provides a base class with as little methods as possible, so that
    # most methods can be delegated via `method_missing`.
    #
    # On Ruby 2.0+ BasicObject could be used for this purpose, but it
    # introduce some extra complexity with constant resolution, so the
    # BlankSlate pattern was prefered.
    # @private
    class BaseDelegator
      kept_methods = [
        # Methods that raise warnings if removed.
        :__id__, :__send__, :object_id,

        # Methods that are explicitly undefined in some subclasses.
        :==, :===,

        # Methods we keep on purpose.
        :class, :respond_to?, :__method__, :method, :dup,
        :clone, :initialize_dup, :initialize_copy, :initialize_clone,
      ]
      instance_methods.each do |method|
        unless kept_methods.include?(method.to_sym)
          undef_method(method)
        end
      end
    end

    # Provides the necessary plumbing to wrap a matcher with a decorator.
    # @private
    class MatcherDelegator < BaseDelegator
      include Composable
      attr_reader :base_matcher

      def initialize(base_matcher)
        @base_matcher = base_matcher
      end

      def method_missing(*args, &block)
        base_matcher.__send__(*args, &block)
      end

      if ::RUBY_VERSION.to_f > 1.8
        def respond_to_missing?(name, include_all=false)
          super || base_matcher.respond_to?(name, include_all)
        end
      else
        # :nocov:
        def respond_to?(name, include_all=false)
          super || base_matcher.respond_to?(name, include_all)
        end
        # :nocov:
      end

      def initialize_copy(other)
        @base_matcher = @base_matcher.clone
        super
      end
    end
  end
end

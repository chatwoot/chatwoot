# frozen_string_literal: true

class RedisClient
  module Decorator
    class << self
      def create(commands_mixin)
        client_decorator = Class.new(Client)
        client_decorator.include(commands_mixin)

        pipeline_decorator = Class.new(Pipeline)
        pipeline_decorator.include(commands_mixin)
        client_decorator.const_set(:Pipeline, pipeline_decorator)

        client_decorator
      end
    end

    module CommandsMixin
      def initialize(client)
        @client = client
      end

      %i(call call_v call_once call_once_v blocking_call blocking_call_v).each do |method|
        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{method}(*args, &block)
            @client.#{method}(*args, &block)
          end
          ruby2_keywords :#{method} if respond_to?(:ruby2_keywords, true)
        RUBY
      end
    end

    class Pipeline
      include CommandsMixin
    end

    class Client
      include CommandsMixin

      def initialize(_client)
        super
        @_pipeline_class = self.class::Pipeline
      end

      def with(*args)
        @client.with(*args) { |c| yield self.class.new(c) }
      end
      ruby2_keywords :with if respond_to?(:ruby2_keywords, true)

      def pipelined(exception: true)
        @client.pipelined(exception: exception) { |p| yield @_pipeline_class.new(p) }
      end

      def multi(**kwargs)
        @client.multi(**kwargs) { |p| yield @_pipeline_class.new(p) }
      end

      %i(close scan hscan sscan zscan).each do |method|
        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{method}(*args, &block)
            @client.#{method}(*args, &block)
          end
          ruby2_keywords :#{method} if respond_to?(:ruby2_keywords, true)
        RUBY
      end

      %i(id config size connect_timeout read_timeout write_timeout pubsub).each do |reader|
        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{reader}
            @client.#{reader}
          end
        RUBY
      end

      %i(timeout connect_timeout read_timeout write_timeout).each do |writer|
        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{writer}=(value)
            @client.#{writer} = value
          end
        RUBY
      end
    end
  end
end

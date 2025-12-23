# frozen_string_literal: true

require "dry/cli/command_registry"

module Dry
  class CLI
    # Registry mixin
    #
    # @since 0.1.0
    module Registry
      # @since 0.1.0
      # @api private
      def self.extended(base)
        base.class_eval do
          @_mutex = Mutex.new
          @commands = CommandRegistry.new
        end
      end

      # Register a command
      #
      # @param name [String] the command name
      # @param command [NilClass,Dry::CLI::Command] the optional command
      # @param aliases [Array<String>] an optional list of aliases
      # @param options [Hash] a set of options
      #
      # @since 0.1.0
      #
      # @example Register a command
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #       end
      #
      #       register "hi", Hello
      #     end
      #   end
      #
      # @example Register a command with aliases
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #       end
      #
      #       register "hello", Hello, aliases: ["hi", "ciao"]
      #     end
      #   end
      #
      # @example Register a group of commands
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       module Generate
      #         class App < Dry::CLI::Command
      #         end
      #
      #         class Action < Dry::CLI::Command
      #         end
      #       end
      #
      #       register "generate", aliases: ["g"] do |prefix|
      #         prefix.register "app",    Generate::App
      #         prefix.register "action", Generate::Action
      #       end
      #     end
      #   end
      def register(name, command = nil, aliases: [], &block)
        @commands.set(name, command, aliases)

        if block_given?
          prefix = Prefix.new(@commands, name, aliases)
          if block.arity.zero?
            prefix.instance_eval(&block)
          else
            yield(prefix)
          end
        end
      end

      # Register a before callback.
      #
      # @param command_name [String] the name used for command registration
      # @param callback [Class, #call] the callback object. If a class is given,
      #   it MUST respond to `#call`.
      # @param blk [Proc] the callback espressed as a block
      #
      # @raise [Dry::CLI::UnknownCommandError] if the command isn't registered
      # @raise [Dry::CLI::InvalidCallbackError] if the given callback doesn't
      #   implement the required interface
      #
      # @since 0.2.0
      #
      # @example
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #         def call(*)
      #           puts "hello"
      #         end
      #       end
      #
      #       register "hello", Hello
      #       before "hello", -> { puts "I'm about to say.." }
      #     end
      #   end
      #
      # @example Register an object as callback
      #   require "dry/cli"
      #
      #   module Callbacks
      #     class Hello
      #       def call(*)
      #         puts "world"
      #       end
      #     end
      #   end
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #         def call(*)
      #           puts "I'm about to say.."
      #         end
      #       end
      #
      #       register "hello", Hello
      #       before "hello", Callbacks::Hello.new
      #     end
      #   end
      #
      # @example Register a class as callback
      #   require "dry/cli"
      #
      #   module Callbacks
      #     class Hello
      #       def call(*)
      #         puts "world"
      #       end
      #     end
      #   end
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #         def call(*)
      #           puts "I'm about to say.."
      #         end
      #       end
      #
      #       register "hello", Hello
      #       before "hello", Callbacks::Hello
      #     end
      #   end
      def before(command_name, callback = nil, &blk)
        @_mutex.synchronize do
          command(command_name).before_callbacks.append(&_callback(callback, blk))
        end
      end

      # Register an after callback.
      #
      # @param command_name [String] the name used for command registration
      # @param callback [Class, #call] the callback object. If a class is given,
      #   it MUST respond to `#call`.
      # @param blk [Proc] the callback espressed as a block
      #
      # @raise [Dry::CLI::UnknownCommandError] if the command isn't registered
      # @raise [Dry::CLI::InvalidCallbackError] if the given callback doesn't
      #   implement the required interface
      #
      # @since 0.2.0
      #
      # @example
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #         def call(*)
      #           puts "hello"
      #         end
      #       end
      #
      #       register "hello", Hello
      #       after "hello", -> { puts "world" }
      #     end
      #   end
      #
      # @example Register an object as callback
      #   require "dry/cli"
      #
      #   module Callbacks
      #     class World
      #       def call(*)
      #         puts "world"
      #       end
      #     end
      #   end
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #         def call(*)
      #           puts "hello"
      #         end
      #       end
      #
      #       register "hello", Hello
      #       after "hello", Callbacks::World.new
      #     end
      #   end
      #
      # @example Register a class as callback
      #   require "dry/cli"
      #
      #   module Callbacks
      #     class World
      #       def call(*)
      #         puts "world"
      #       end
      #     end
      #   end
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #         def call(*)
      #           puts "hello"
      #         end
      #       end
      #
      #       register "hello", Hello
      #       after "hello", Callbacks::World
      #     end
      #   end
      def after(command_name, callback = nil, &blk)
        @_mutex.synchronize do
          command(command_name).after_callbacks.append(&_callback(callback, blk))
        end
      end

      # @since 0.1.0
      # @api private
      def get(arguments)
        @commands.get(arguments)
      end

      private

      COMMAND_NAME_SEPARATOR = " "

      # @since 0.2.0
      # @api private
      def command(command_name)
        get(command_name.split(COMMAND_NAME_SEPARATOR)).tap do |result|
          raise UnknownCommandError, command_name unless result.found?
        end
      end

      # @since 0.2.0
      # @api private
      #
      def _callback(callback, blk)
        return blk if blk.respond_to?(:to_proc)

        case callback
        when ->(c) { c.respond_to?(:call) }
          callback.method(:call)
        when Class
          begin
            _callback(callback.new, blk)
          rescue ArgumentError
            raise InvalidCallbackError, callback
          end
        else
          raise InvalidCallbackError, callback
        end
      end

      # Command name prefix
      #
      # @since 0.1.0
      class Prefix
        # @since 0.1.0
        # @api private
        def initialize(registry, prefix, aliases)
          @registry = registry
          @prefix   = prefix

          registry.set(prefix, nil, aliases)
        end

        # @since 0.1.0
        #
        # @see Dry::CLI::Registry#register
        def register(name, command, aliases: [])
          command_name = "#{prefix} #{name}"
          registry.set(command_name, command, aliases)
        end

        private

        # @since 0.1.0
        # @api private
        attr_reader :registry

        # @since 0.1.0
        # @api private
        attr_reader :prefix
      end
    end
  end
end

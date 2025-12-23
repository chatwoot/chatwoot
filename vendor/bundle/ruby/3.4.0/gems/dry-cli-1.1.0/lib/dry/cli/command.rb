# frozen_string_literal: true

require "forwardable"
require "dry/cli/option"

module Dry
  class CLI
    # Base class for commands
    #
    # @since 0.1.0
    class Command
      # @since 0.1.0
      # @api private
      def self.inherited(base)
        super
        base.class_eval do
          @_mutex       = Mutex.new
          @description  = nil
          @examples     = []
          @subcommands  = []
          @arguments = base.superclass_arguments || []
          @options = base.superclass_options || []
        end
        base.extend ClassMethods
      end

      # @since 0.1.0
      # @api private
      module ClassMethods
        # @since 0.1.0
        # @api private
        attr_reader :description

        # @since 0.1.0
        # @api private
        attr_reader :examples

        # @since 0.1.0
        # @api private
        attr_reader :arguments

        # @since 0.1.0
        # @api private
        attr_reader :options

        # @since 0.7.0
        # @api private
        attr_accessor :subcommands
      end

      # Set the description of the command
      #
      # @param description [String] the description
      #
      # @since 0.1.0
      #
      # @example
      #   require "dry/cli"
      #
      #   class Echo < Dry::CLI::Command
      #     desc "Prints given input"
      #
      #     def call(*)
      #       # ...
      #     end
      #   end
      def self.desc(description)
        @description = description
      end

      # Describe the usage of the command
      #
      # @param examples [Array<String>] one or more examples
      #
      # @since 0.1.0
      #
      # @example
      #   require "dry/cli"
      #
      #   class Server < Dry::CLI::Command
      #     example [
      #       "                    # Basic usage (it uses the bundled server engine)",
      #       "--server=webrick    # Force `webrick` server engine",
      #       "--host=0.0.0.0      # Bind to a host",
      #       "--port=2306         # Bind to a port",
      #       "--no-code-reloading # Disable code reloading"
      #     ]
      #
      #     def call(*)
      #       # ...
      #     end
      #   end
      #
      #   # $ foo server --help
      #   #   # ...
      #   #
      #   #   Examples:
      #   #     foo server                     # Basic usage (it uses the bundled server engine)
      #   #     foo server --server=webrick    # Force `webrick` server engine
      #   #     foo server --host=0.0.0.0      # Bind to a host
      #   #     foo server --port=2306         # Bind to a port
      #   #     foo server --no-code-reloading # Disable code reloading
      def self.example(*examples)
        @examples += examples.flatten(1)
      end

      # Specify an argument
      #
      # @param name [Symbol] the argument name
      # @param options [Hash] a set of options
      #
      # @since 0.1.0
      #
      # @example Optional argument
      #   require "dry/cli"
      #
      #   class Hello < Dry::CLI::Command
      #     argument :name
      #
      #     def call(name: nil, **)
      #       if name.nil?
      #         puts "Hello, stranger"
      #       else
      #         puts "Hello, #{name}"
      #       end
      #     end
      #   end
      #
      #   # $ foo hello
      #   #   Hello, stranger
      #
      #   # $ foo hello Luca
      #   #   Hello, Luca
      #
      # @example Required argument
      #   require "dry/cli"
      #
      #   class Hello < Dry::CLI::Command
      #     argument :name, required: true
      #
      #     def call(name:, **)
      #       puts "Hello, #{name}"
      #     end
      #   end
      #
      #   # $ foo hello Luca
      #   #   Hello, Luca
      #
      #   # $ foo hello
      #   #   ERROR: "foo hello" was called with no arguments
      #   #   Usage: "foo hello NAME"
      #
      # @example Multiple arguments
      #   require "dry/cli"
      #
      #   module Generate
      #     class Action < Dry::CLI::Command
      #       argument :app,    required: true
      #       argument :action, required: true
      #
      #       def call(app:, action:, **)
      #         puts "Generating action: #{action} for app: #{app}"
      #       end
      #     end
      #   end
      #
      #   # $ foo generate action web home
      #   #   Generating action: home for app: web
      #
      #   # $ foo generate action
      #   #   ERROR: "foo generate action" was called with no arguments
      #   #   Usage: "foo generate action APP ACTION"
      #
      # @example Description
      #   require "dry/cli"
      #
      #   class Hello < Dry::CLI::Command
      #     argument :name, desc: "The name of the person to greet"
      #
      #     def call(name: nil, **)
      #       # ...
      #     end
      #   end
      #
      #   # $ foo hello --help
      #   #   Command:
      #   #     foo hello
      #   #
      #   #   Usage:
      #   #     foo hello [NAME]
      #   #
      #   #   Arguments:
      #   #     NAME                # The name of the person to greet
      #   #
      #   #   Options:
      #   #     --help, -h          # Print this help
      def self.argument(name, options = {})
        @arguments << Argument.new(name, options)
      end

      # Command line option (aka optional argument)
      #
      # @param name [Symbol] the param name
      # @param options [Hash] a set of options
      #
      # @since 0.1.0
      #
      # @example Basic usage
      #   require "dry/cli"
      #
      #   class Console < Dry::CLI::Command
      #     option :engine
      #
      #     def call(engine: nil, **)
      #       puts "starting console (engine: #{engine || :irb})"
      #     end
      #   end
      #
      #   # $ foo console
      #   # starting console (engine: irb)
      #
      #   # $ foo console --engine=pry
      #   # starting console (engine: pry)
      #
      # @example List values
      #   require "dry/cli"
      #
      #   class Console < Dry::CLI::Command
      #     option :engine, values: %w(irb pry ripl)
      #
      #     def call(engine: nil, **)
      #       puts "starting console (engine: #{engine || :irb})"
      #     end
      #   end
      #
      #   # $ foo console
      #   # starting console (engine: irb)
      #
      #   # $ foo console --engine=pry
      #   # starting console (engine: pry)
      #
      #   # $ foo console --engine=foo
      #   # ERROR: Invalid param provided
      #
      # @example Description
      #   require "dry/cli"
      #
      #   class Console < Dry::CLI::Command
      #     option :engine, desc: "Force a console engine"
      #
      #     def call(engine: nil, **)
      #       # ...
      #     end
      #   end
      #
      #   # $ foo console --help
      #   # # ...
      #   #
      #   # Options:
      #   #   --engine=VALUE                  # Force a console engine: (irb/pry/ripl)
      #   #   --help, -h                      # Print this help
      #
      # @example Boolean
      #   require "dry/cli"
      #
      #   class Server < Dry::CLI::Command
      #     option :code_reloading, type: :boolean, default: true
      #
      #     def call(code_reloading:, **)
      #       puts "staring server (code reloading: #{code_reloading})"
      #     end
      #   end
      #
      #   # $ foo server
      #   # starting server (code reloading: true)
      #
      #   # $ foo server --no-code-reloading
      #   # starting server (code reloading: false)
      #
      #   # $ foo server --help
      #   # # ...
      #   #
      #   # Options:
      #   #   --[no]-code-reloading
      #
      # @example Aliases
      #   require "dry/cli"
      #
      #   class Server < Dry::CLI::Command
      #     option :port, aliases: ["-p"]
      #
      #     def call(options)
      #       puts "staring server (port: #{options.fetch(:port, 2300)})"
      #     end
      #   end
      #
      #   # $ foo server
      #   # starting server (port: 2300)
      #
      #   # $ foo server --port=2306
      #   # starting server (port: 2306)
      #
      #   # $ foo server -p 2306
      #   # starting server (port: 2306)
      #
      #   # $ foo server --help
      #   # # ...
      #   #
      #   # Options:
      #   #   --port=VALUE, -p VALUE
      def self.option(name, options = {})
        @options << Option.new(name, options)
      end

      # @since 0.1.0
      # @api private
      def self.params
        @_mutex.synchronize do
          (@arguments + @options).uniq
        end
      end

      # @since 0.1.0
      # @api private
      def self.default_params
        params.each_with_object({}) do |param, result|
          result[param.name] = param.default unless param.default.nil?
        end
      end

      # @since 0.1.0
      # @api private
      def self.required_arguments
        arguments.select(&:required?)
      end

      # @since 0.1.0
      # @api private
      def self.optional_arguments
        arguments.reject(&:required?)
      end

      # @since 0.7.0
      # @api private
      def self.subcommands
        subcommands
      end

      # @since 0.7.0
      # @api private
      def self.superclass_variable_dup(var)
        if superclass.instance_variable_defined?(var)
          superclass.instance_variable_get(var).dup
        end
      end

      # @since 0.7.0
      # @api private
      def self.superclass_arguments
        superclass_variable_dup(:@arguments)
      end

      # @since 0.7.0
      # @api private
      def self.superclass_options
        superclass_variable_dup(:@options)
      end

      extend Forwardable

      delegate %i[
        description
        examples
        arguments
        options
        params
        default_params
        required_arguments
        optional_arguments
        subcommands
      ] => "self.class"
    end
  end
end

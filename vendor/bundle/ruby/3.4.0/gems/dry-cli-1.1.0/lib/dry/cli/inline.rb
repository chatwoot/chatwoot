# frozen_string_literal: true

require "backports/2.5.0/module/define_method" if RUBY_VERSION < "2.5"

module Dry
  class CLI
    require "dry/cli"
    # Inline Syntax (aka DSL) to implement one-file applications
    #
    # `dry/cli/inline` is not required by default
    # and explicit requirement of this file means that
    # it is expected of abusing global namespace with
    # methods below
    #
    # DSL consists of 5 methods:
    # `desc`, `example`, `argument`, `option` 
    # — are similar to methods from Command class
    #
    # `run` accepts a block to execute
    #
    # @example
    #   require 'bundler/inline'
    #   gemfile { gem 'dry/cli', require: 'dry/cli/inline' }
    #
    #   desc 'List files in a directory'
    #   argument :path, required: false, desc: '[DIR]'
    #   option :all, aliases: ['a'], type: :boolean
    #
    #   run do |path: '.', **options|
    #     puts options.key?(:all) ? Dir.entries(path) : Dir.children(path)
    #   end
    #
    #   # $ ls -a
    #   # $ ls somepath
    #   # $ ls somepath --all
    # @since 0.6.0
    module Inline
      extend Forwardable

      # AnonymousCommand
      #
      # @since 0.6.0
      AnonymousCommand = Class.new(Dry::CLI::Command)

      # @since 0.6.0
      delegate %i[desc example argument option] => AnonymousCommand

      # The rule of thumb for implementation of run block
      # is that for every argument from your CLI
      # you need to specify that as an mandatory argument for a block.
      # Optional arguments have to have default value as ruby syntax expect them
      #
      # @example
      #   argument :one
      #   argument :two, required: false
      #   option :three
      #
      #   run do |one:, two: 'default', **options|
      #     puts one, two, options.inspect
      #   end
      #
      # @since 0.6.0
      def run(arguments: ARGV, out: $stdout)
        command = AnonymousCommand
        command.define_method(:call) do |**args|
          yield(**args)
        end

        Dry.CLI(command).call(arguments: arguments, out: out)
      end
    end
  end
end

include Dry::CLI::Inline # rubocop:disable Style/MixinUsage

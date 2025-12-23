# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for direct access to environment variables through the
      # `ENV` variable within the application code. This can lead to runtime
      # errors due to misconfiguration that could have been discovered at boot
      # time if the environment variables were loaded as part of initialization
      # and copied into the application's configuration or secrets. The cop can
      # be configured to allow either reads or writes if required.
      #
      # @example
      #   # good
      #   Rails.application.config.foo
      #   Rails.application.config.x.foo.bar
      #   Rails.application.secrets.foo
      #   Rails.application.config.foo = "bar"
      #
      # @example AllowReads: false (default)
      #   # bad
      #   ENV["FOO"]
      #   ENV.fetch("FOO")
      #
      # @example AllowReads: true
      #   # good
      #   ENV["FOO"]
      #   ENV.fetch("FOO")
      #
      # @example AllowWrites: false (default)
      #   # bad
      #   ENV["FOO"] = "bar"
      #
      # @example AllowWrites: true
      #   # good
      #   ENV["FOO"] = "bar"
      class EnvironmentVariableAccess < Base
        READ_MSG = 'Do not read from `ENV` directly post initialization.'
        WRITE_MSG = 'Do not write to `ENV` directly post initialization.'

        def on_const(node)
          add_offense(node, message: READ_MSG) if env_read?(node) && !allow_reads?
          add_offense(node, message: WRITE_MSG) if env_write?(node) && !allow_writes?
        end

        def_node_search :env_read?, <<~PATTERN
          ^(send (const {cbase nil?} :ENV) !:[]= ...)
        PATTERN

        def_node_search :env_write?, <<~PATTERN
          {^(indexasgn (const {cbase nil?} :ENV) ...)
           ^(send (const {cbase nil?} :ENV) :[]= ...)}
        PATTERN

        private

        def allow_reads?
          cop_config['AllowReads'] == true
        end

        def allow_writes?
          cop_config['AllowWrites'] == true
        end
      end
    end
  end
end

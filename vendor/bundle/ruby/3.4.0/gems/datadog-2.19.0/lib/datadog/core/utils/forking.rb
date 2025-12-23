# frozen_string_literal: true

module Datadog
  module Core
    module Utils
      # Helper methods for managing forking behavior
      module Forking
        def self.included(base)
          base.prepend(ClassExtensions) if base.is_a?(Class)
        end

        def self.extended(base)
          # Explicitly update PID here because there's a case where
          # the code path that lazily updates the PID may not be exercised
          # until after a fork occurs, thus causing the event to be missed.
          # By eagerly setting this, we avoid this scenario.
          base.update_fork_pid!
        end

        def after_fork!
          if forked?
            yield
            update_fork_pid!
            true
          else
            false
          end
        end

        def forked?
          Process.pid != fork_pid
        end

        def update_fork_pid!
          @fork_pid = Process.pid
        end

        def fork_pid
          @fork_pid ||= Process.pid
        end

        # Adds additional functionality for Classes that implement Forking
        module ClassExtensions
          # Addresses an edge case where forking before invoking #update_fork_pid! on the
          # object will cause forking to not be detected in the fork when it should have.
          #
          # This wrapper prevents this by initializing the fork PID when the object is created.
          if RUBY_VERSION >= '3'
            def initialize(*args, **kwargs, &block)
              super
              update_fork_pid!
            end
          else
            def initialize(*args, &block)
              super
              update_fork_pid!
            end
          end
        end
      end
    end
  end
end

# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module IgnoreActions
        def self.is_filtered?(key, klass, action_name)
          # We'll walk the superclass chain and see if
          # any class says 'yes, filter this one'.

          while klass.respond_to?(:newrelic_read_attr)
            ignore_actions = klass.newrelic_read_attr(key)

            should_filter = case ignore_actions
            when Hash
              only_actions = Array(ignore_actions[:only])
              except_actions = Array(ignore_actions[:except])
              action_name = action_name.to_sym

              only_actions.include?(action_name) || (!except_actions.empty? && !except_actions.include?(action_name))
            else
              !ignore_actions.nil?
            end

            return true if should_filter

            # Nothing so far says we should filter,
            # so keep checking up the superclass chain.
            klass = klass.superclass
          end

          # Getting here means that no class filtered this.
          false
        end
      end
    end
  end
end

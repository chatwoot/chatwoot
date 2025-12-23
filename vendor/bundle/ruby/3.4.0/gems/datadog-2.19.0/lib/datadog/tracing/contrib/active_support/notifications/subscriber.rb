# frozen_string_literal: true

require 'set'
require_relative 'subscription'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Notifications
          # For classes that listen to ActiveSupport::Notification events.
          # Creates subscriptions that are wrapped with tracing.
          module Subscriber
            def self.included(base)
              base.extend(ClassMethods)
            end

            # Class methods that are implemented in the inheriting class.
            module ClassMethods
              # Returns a list of subscriptions created for this class.
              def subscriptions
                @subscriptions ||= Set.new
              end

              # Returns whether subscriptions have been activated, via #subscribe!
              def subscribed?
                subscribed == true
              end

              protected

              # Defines a callback for when subscribe! is called.
              # Should contain subscription setup, defined by the inheriting class.
              def on_subscribe(&block)
                @on_subscribe_block = block
              end

              # Runs the on_subscribe callback once, to activate subscriptions.
              # Should be triggered by the inheriting class.
              def subscribe!
                return subscribed? if subscribed? || on_subscribe_block.nil?

                on_subscribe_block.call
                @subscribed = true
              end

              # Creates a subscription and immediately activates it.
              def subscribe(pattern, span_name, span_options = {}, on_start: nil, on_finish: nil, trace: nil)
                subscription(
                  span_name,
                  span_options,
                  on_start: on_start,
                  on_finish: on_finish,
                  trace: trace
                ).tap do |subscription|
                  subscription.subscribe(pattern)
                end
              end

              # Creates a subscription without activating it.
              # Subscription is added to the inheriting class' list of subscriptions.
              def subscription(span_name, span_options = {}, on_start: nil, on_finish: nil, trace: nil)
                Subscription.new(
                  span_name,
                  span_options,
                  on_start: on_start,
                  on_finish: on_finish,
                  trace: trace
                ).tap do |subscription|
                  subscriptions << subscription
                end
              end

              private

              attr_reader :subscribed, :on_subscribe_block
            end
          end
        end
      end
    end
  end
end

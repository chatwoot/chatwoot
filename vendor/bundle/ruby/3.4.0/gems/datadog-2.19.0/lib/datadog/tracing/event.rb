# frozen_string_literal: true

module Datadog
  module Tracing
    # Event behavior and DSL
    module Events
      def self.included(base)
        base.extend(ClassMethods)
        base.include(InstanceMethods)
      end

      # Class methods
      module ClassMethods
        def build(**event_handlers)
          events = new
          events.subscribe(**event_handlers)
          events
        end
      end

      # Instance methods
      module InstanceMethods
        def subscribe(**event_handlers)
          return unless event_handlers

          event_handlers.each do |event_name, handlers|
            handlers.each do |handler_name, handler|
              events.send(event_name).subscribe(handler_name, &handler)
            end
          end

          event_handlers
        end
      end
    end

    # A simple pub-sub event model for components to exchange messages through.
    class Event
      attr_reader \
        :name,
        :subscriptions

      def initialize(name)
        @name = name
        @subscriptions = []
      end

      def subscribe(&block)
        raise ArgumentError, 'Must give a block to subscribe!' unless block

        subscriptions << block
      end

      def unsubscribe_all!
        subscriptions.clear

        true
      end

      def publish(*args)
        subscriptions.each do |block|
          begin
            block.call(*args)
          rescue StandardError => e
            Datadog.logger.debug do
              "Error while handling '#{name}' event with '#{block}': #{e.class.name} #{e.message} " \
              "at #{Array(e.backtrace).first}"
            end
          end
        end

        true
      end
    end
  end
end

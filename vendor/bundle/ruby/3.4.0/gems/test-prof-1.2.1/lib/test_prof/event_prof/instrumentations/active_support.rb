# frozen_string_literal: true

module TestProf::EventProf
  module Instrumentations
    # Wrapper over ActiveSupport::Notifications
    module ActiveSupport
      class Subscriber
        attr_reader :block, :started_at

        def initialize(block)
          @block = block
        end

        def start(*)
          @started_at = TestProf.now
        end

        def publish(_name, started_at, finished_at, *)
          block.call(finished_at - started_at)
        end

        def finish(*)
          block.call(TestProf.now - started_at)
        end
      end

      class << self
        def subscribe(event, &block)
          raise ArgumentError, "Block is required!" unless block

          ::ActiveSupport::Notifications.subscribe(event, Subscriber.new(block))
        end

        def instrument(event)
          ::ActiveSupport::Notifications.instrument(event) { yield }
        end
      end
    end
  end
end

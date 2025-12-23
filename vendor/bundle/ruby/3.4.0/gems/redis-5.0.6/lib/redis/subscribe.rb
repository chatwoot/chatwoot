# frozen_string_literal: true

class Redis
  class SubscribedClient
    def initialize(client)
      @client = client
      @write_monitor = Monitor.new
    end

    def call_v(command)
      @write_monitor.synchronize do
        @client.call_v(command)
      end
    end

    def subscribe(*channels, &block)
      subscription("subscribe", "unsubscribe", channels, block)
    end

    def subscribe_with_timeout(timeout, *channels, &block)
      subscription("subscribe", "unsubscribe", channels, block, timeout)
    end

    def psubscribe(*channels, &block)
      subscription("psubscribe", "punsubscribe", channels, block)
    end

    def psubscribe_with_timeout(timeout, *channels, &block)
      subscription("psubscribe", "punsubscribe", channels, block, timeout)
    end

    def unsubscribe(*channels)
      call_v([:unsubscribe, *channels])
    end

    def punsubscribe(*channels)
      call_v([:punsubscribe, *channels])
    end

    def close
      @client.close
    end

    protected

    def subscription(start, stop, channels, block, timeout = 0)
      sub = Subscription.new(&block)

      call_v([start, *channels])
      while event = @client.next_event(timeout)
        if event.is_a?(::RedisClient::CommandError)
          raise Client::ERROR_MAPPING.fetch(event.class), event.message
        end

        type, *rest = event
        if callback = sub.callbacks[type]
          callback.call(*rest)
        end
        break if type == stop && rest.last == 0
      end
      # No need to unsubscribe here. The real client closes the connection
      # whenever an exception is raised (see #ensure_connected).
    end
  end

  class Subscription
    attr :callbacks

    def initialize
      @callbacks = {}
      yield(self)
    end

    def subscribe(&block)
      @callbacks["subscribe"] = block
    end

    def unsubscribe(&block)
      @callbacks["unsubscribe"] = block
    end

    def message(&block)
      @callbacks["message"] = block
    end

    def psubscribe(&block)
      @callbacks["psubscribe"] = block
    end

    def punsubscribe(&block)
      @callbacks["punsubscribe"] = block
    end

    def pmessage(&block)
      @callbacks["pmessage"] = block
    end
  end
end

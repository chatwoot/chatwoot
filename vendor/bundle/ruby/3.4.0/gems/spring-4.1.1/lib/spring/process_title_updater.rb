module Spring
  # Yes, I know this reimplements a bunch of stuff in Active Support, but
  # I don't want the Spring client to depend on AS, in order to keep its
  # load time down.
  class ProcessTitleUpdater
    SECOND = 1
    MINUTE = 60
    HOUR   = 60*60

    def self.run(&block)
      updater = new(&block)

      Spring.failsafe_thread {
        $0 = updater.value
        loop { $0 = updater.next }
      }
    end

    attr_reader :block

    def initialize(start = Time.now, &block)
      @start = start
      @block = block
    end

    def interval
      distance = Time.now - @start

      if distance < MINUTE
        SECOND
      elsif distance < HOUR
        MINUTE
      else
        HOUR
      end
    end

    def next
      sleep interval
      value
    end

    def value
      block.call(distance_in_words)
    end

    def distance_in_words(now = Time.now)
      distance = now - @start

      if distance < MINUTE
        pluralize(distance, "sec")
      elsif distance < HOUR
        pluralize(distance / MINUTE, "min")
      else
        pluralize(distance / HOUR, "hour")
      end
    end

    private

    def pluralize(amount, unit)
      "#{amount.to_i} #{amount.to_i == 1 ? unit : "#{unit}s"}"
    end
  end
end

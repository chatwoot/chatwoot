module Retriable
  class ExponentialBackoff
    ATTRIBUTES = [
      :tries,
      :base_interval,
      :multiplier,
      :max_interval,
      :rand_factor,
    ].freeze

    attr_accessor(*ATTRIBUTES)

    def initialize(opts = {})
      @tries         = 3
      @base_interval = 0.5
      @max_interval  = 60
      @rand_factor   = 0.5
      @multiplier    = 1.5

      opts.each do |k, v|
        raise ArgumentError, "#{k} is not a valid option" if !ATTRIBUTES.include?(k)
        instance_variable_set(:"@#{k}", v)
      end
    end

    def intervals
      intervals = Array.new(tries) do |iteration|
        [base_interval * multiplier**iteration, max_interval].min
      end

      return intervals if rand_factor.zero?

      intervals.map { |i| randomize(i) }
    end

    private

    def randomize(interval)
      delta = rand_factor * interval * 1.0
      min = interval - delta
      max = interval + delta
      rand(min..max)
    end
  end
end

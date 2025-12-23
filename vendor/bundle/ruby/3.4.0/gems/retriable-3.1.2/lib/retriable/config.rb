require_relative "exponential_backoff"

module Retriable
  class Config
    ATTRIBUTES = ExponentialBackoff::ATTRIBUTES + [
      :sleep_disabled,
      :max_elapsed_time,
      :intervals,
      :timeout,
      :on,
      :on_retry,
      :contexts,
    ].freeze

    attr_accessor(*ATTRIBUTES)

    def initialize(opts = {})
      backoff = ExponentialBackoff.new

      @tries            = backoff.tries
      @base_interval    = backoff.base_interval
      @max_interval     = backoff.max_interval
      @rand_factor      = backoff.rand_factor
      @multiplier       = backoff.multiplier
      @sleep_disabled   = false
      @max_elapsed_time = 900 # 15 min
      @intervals        = nil
      @timeout          = nil
      @on               = [StandardError]
      @on_retry         = nil
      @contexts         = {}

      opts.each do |k, v|
        raise ArgumentError, "#{k} is not a valid option" if !ATTRIBUTES.include?(k)
        instance_variable_set(:"@#{k}", v)
      end
    end

    def to_h
      ATTRIBUTES.each_with_object({}) do |key, hash|
        hash[key] = public_send(key)
      end
    end
  end
end

# frozen_string_literal: true

module Judoscale
  class RequestMetrics
    MILLISECONDS_CUTOFF = Time.new(2000, 1, 1).to_i * 1000
    MICROSECONDS_CUTOFF = MILLISECONDS_CUTOFF * 1000
    NANOSECONDS_CUTOFF = MICROSECONDS_CUTOFF * 1000

    attr_reader :request_id, :size, :network_time

    def initialize(env, config = Config.instance)
      @config = config
      @request_id = env["HTTP_X_REQUEST_ID"]
      @size = env["rack.input"].respond_to?(:size) ? env["rack.input"].size : 0
      @network_time = env["puma.request_body_wait"].to_i
      @request_start_header = env["HTTP_X_REQUEST_START"]
    end

    def ignore?
      @config.ignore_large_requests? && @size > @config.max_request_size_bytes
    end

    def started_at
      if @request_start_header
        # There are several variants of this header. We handle these:
        #   - whole milliseconds (Heroku)
        #   - whole microseconds (???)
        #   - whole nanoseconds (Render)
        #   - fractional seconds (NGINX)
        #   - preceeding "t=" (NGINX)
        value = @request_start_header.gsub(/[^0-9.]/, "").to_f

        # `value` could be seconds, milliseconds, microseconds or nanoseconds.
        # We use some arbitrary cutoffs to determine which one it is.

        if value > NANOSECONDS_CUTOFF
          Time.at(value / 1_000_000_000.0)
        elsif value > MICROSECONDS_CUTOFF
          Time.at(value / 1_000_000.0)
        elsif value > MILLISECONDS_CUTOFF
          Time.at(value / 1000.0)
        else
          Time.at(value)
        end
      end
    end

    def queue_time(now = Time.now)
      return if started_at.nil?

      queue_time = ((now - started_at) * 1000).to_i

      # Subtract the time Puma spent waiting on the request body, i.e. the network time. It's irrelevant to
      # capacity-related queue time. Without this, slow clients and large request payloads will skew queue time.
      queue_time -= network_time

      # Safeguard against negative queue times (should not happen in practice)
      (queue_time > 0) ? queue_time : 0
    end
  end
end

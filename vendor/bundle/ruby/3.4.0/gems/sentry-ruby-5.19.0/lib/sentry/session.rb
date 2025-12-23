# frozen_string_literal: true

module Sentry
  class Session
    attr_reader :started, :status, :aggregation_key

    # TODO-neel add :crashed after adding handled mechanism
    STATUSES = %i[ok errored exited]
    AGGREGATE_STATUSES = %i[errored exited]

    def initialize
      @started = Sentry.utc_now
      @status = :ok

      # truncate seconds from the timestamp since we only care about
      # minute level granularity for aggregation
      @aggregation_key = Time.utc(@started.year, @started.month, @started.day, @started.hour, @started.min)
    end

    # TODO-neel add :crashed after adding handled mechanism
    def update_from_exception(_exception = nil)
      @status = :errored
    end

    def close
      @status = :exited if @status == :ok
    end

    def deep_dup
      dup
    end
  end
end

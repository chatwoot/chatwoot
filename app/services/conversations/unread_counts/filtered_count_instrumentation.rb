class Conversations::UnreadCounts::FilteredCountInstrumentation
  # Centralizes the rollout-critical filtered unread count signals:
  # API response duration, counter duration, snapshot build duration, snapshot state distribution,
  # refresh claim rate, build lock acquisition rate, and invalidation/version bump rate.
  EVENT_NAME = 'FilteredUnreadCounts'.freeze
  METRIC_PREFIX = 'Custom/Conversations/UnreadCounts/Filtered'.freeze
  SUMMARY_KEY = :filtered_unread_counts_request_summary
  AGGREGATED_INCREMENT_OPERATIONS = %i[snapshot_state refresh_claim build_lock].freeze
  SNAPSHOT_STATUSES = %i[fresh stale missing expired].freeze
  SNAPSHOT_SCOPES = %i[built_in_filter folder_index filter].freeze
  SUMMARY_DEFAULTS = begin
    defaults = {
      snapshot_total_count: 0,
      refresh_claimed_count: 0,
      refresh_skipped_count: 0,
      build_lock_acquired_count: 0,
      build_lock_missed_count: 0,
      snapshot_build_success_count: 0,
      snapshot_build_error_count: 0
    }

    SNAPSHOT_STATUSES.each { |status| defaults[:"snapshot_#{status}_count"] = 0 }
    SNAPSHOT_SCOPES.each do |scope|
      defaults[:"#{scope}_snapshot_count"] = 0
      defaults[:"#{scope}_refresh_claimed_count"] = 0
      defaults[:"#{scope}_refresh_skipped_count"] = 0
      defaults[:"#{scope}_build_lock_acquired_count"] = 0
      defaults[:"#{scope}_build_lock_missed_count"] = 0
      defaults[:"#{scope}_snapshot_build_success_count"] = 0
      defaults[:"#{scope}_snapshot_build_error_count"] = 0
    end

    defaults.freeze
  end
  private_constant :SUMMARY_KEY, :AGGREGATED_INCREMENT_OPERATIONS, :SNAPSHOT_STATUSES, :SNAPSHOT_SCOPES, :SUMMARY_DEFAULTS

  class << self
    def summarize_request(account_id:)
      previous_summary = current_summary
      summary = request_summary(account_id)
      Thread.current[SUMMARY_KEY] = summary
      started_at = monotonic_time
      status = :success

      yield
    rescue StandardError => e
      status = :error
      summary[:error_class] = e.class.name
      raise
    ensure
      record_request_summary(summary, status, started_at)
      Thread.current[SUMMARY_KEY] = previous_summary
    end

    def observe(operation, attributes = {})
      started_at = monotonic_time

      yield.tap do
        record_observation(operation, attributes, started_at, status: :success)
      end
    rescue StandardError => e
      record_observation(operation, attributes.merge(error_class: e.class.name), started_at, status: :error)
      raise
    end

    def increment(operation, attributes = {})
      record_increment_summary(operation, attributes) if aggregated_increment?(operation)
      record_event(operation, attributes) unless aggregated_increment?(operation)
      record_metric("#{metric_name(operation)}/count", 1)
    end

    def record_event(operation, attributes = {})
      agent = new_relic_agent
      return unless agent.respond_to?(:record_custom_event)

      agent.record_custom_event(EVENT_NAME, sanitized_attributes(attributes.merge(operation: operation)))
    rescue StandardError
      nil
    end

    private

    def record_observation(operation, attributes, started_at, status:)
      duration_ms = elapsed_ms_since(started_at)
      record_observation_summary(operation, attributes, status: status)
      record_metric("#{metric_name(operation)}/duration_ms", duration_ms)
    end

    def record_request_summary(summary, status, started_at)
      duration_ms = elapsed_ms_since(started_at)
      summary[:status] = status
      summary[:duration_ms] = duration_ms
      record_metric("#{metric_name(:api_response)}/duration_ms", duration_ms)
      record_event(:request_summary, summary)
    end

    def record_metric(name, value)
      agent = new_relic_agent
      return unless agent.respond_to?(:record_metric)

      agent.record_metric(name, value)
    rescue StandardError
      nil
    end

    def metric_name(operation)
      "#{METRIC_PREFIX}/#{operation}"
    end

    def request_summary(account_id)
      SUMMARY_DEFAULTS.dup.merge(account_id: account_id)
    end

    def current_summary
      Thread.current[SUMMARY_KEY]
    end

    def aggregated_increment?(operation)
      operation.in?(AGGREGATED_INCREMENT_OPERATIONS)
    end

    def record_increment_summary(operation, attributes)
      case operation
      when :snapshot_state
        record_snapshot_state_summary(attributes)
      when :refresh_claim
        result = attributes[:claimed] ? :claimed : :skipped
        increment_summary_count(:"refresh_#{result}_count")
        increment_scoped_summary_count(attributes[:snapshot_scope], :"refresh_#{result}_count")
      when :build_lock
        result = attributes[:acquired] ? :acquired : :missed
        increment_summary_count(:"build_lock_#{result}_count")
        increment_scoped_summary_count(attributes[:snapshot_scope], :"build_lock_#{result}_count")
      end
    end

    def record_snapshot_state_summary(attributes)
      increment_summary_count(:snapshot_total_count)
      increment_summary_count(:"snapshot_#{attributes[:snapshot_status]}_count")
      increment_scoped_summary_count(attributes[:snapshot_scope], :snapshot_count)
    end

    def record_observation_summary(operation, attributes, status:)
      return unless operation == :snapshot_build

      result = status == :success ? :success : :error
      increment_summary_count(:"snapshot_build_#{result}_count")
      increment_scoped_summary_count(attributes[:snapshot_scope], :"snapshot_build_#{result}_count")
    end

    def increment_scoped_summary_count(scope, suffix)
      return if scope.blank?

      increment_summary_count(:"#{scope}_#{suffix}")
    end

    def increment_summary_count(key)
      return if current_summary.blank?

      current_summary[key] = current_summary.fetch(key, 0) + 1
    end

    def sanitized_attributes(attributes)
      attributes.compact.transform_values do |value|
        case value
        when String, Integer, Float, TrueClass, FalseClass
          value
        else
          value.to_s
        end
      end
    end

    def elapsed_ms_since(started_at)
      ((monotonic_time - started_at) * 1000).round(2)
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def new_relic_agent
      return unless defined?(::NewRelic::Agent)

      ::NewRelic::Agent
    end
  end
end

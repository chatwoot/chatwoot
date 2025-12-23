# frozen_string_literal: true

require 'securerandom'
require 'sentry/cron/monitor_config'

module Sentry
  class CheckInEvent < Event
    TYPE = 'check_in'

    # uuid to identify this check-in.
    # @return [String]
    attr_accessor :check_in_id

    # Identifier of the monitor for this check-in.
    # @return [String]
    attr_accessor :monitor_slug

    # Duration of this check since it has started in seconds.
    # @return [Integer, nil]
    attr_accessor :duration

    # Monitor configuration to support upserts.
    # @return [Cron::MonitorConfig, nil]
    attr_accessor :monitor_config

    # Status of this check-in.
    # @return [Symbol]
    attr_accessor :status

    VALID_STATUSES = %i[ok in_progress error]

    def initialize(
      slug:,
      status:,
      duration: nil,
      monitor_config: nil,
      check_in_id: nil,
      **options
    )
      super(**options)

      self.monitor_slug = slug
      self.status = status
      self.duration = duration
      self.monitor_config = monitor_config
      self.check_in_id = check_in_id || SecureRandom.uuid.delete('-')
    end

    # @return [Hash]
    def to_hash
      data = super
      data[:check_in_id] = check_in_id
      data[:monitor_slug] = monitor_slug
      data[:status] = status
      data[:duration] = duration if duration
      data[:monitor_config] = monitor_config.to_hash if monitor_config
      data
    end
  end
end

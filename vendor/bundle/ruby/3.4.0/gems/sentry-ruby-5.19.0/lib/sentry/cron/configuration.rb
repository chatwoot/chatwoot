# frozen_string_literal: true

module Sentry
  module Cron
    class Configuration
      # Defaults set here will apply to all {Cron::MonitorConfig} objects unless overwritten.

      # How long (in minutes) after the expected checkin time will we wait
      # until we consider the checkin to have been missed.
      # @return [Integer, nil]
      attr_accessor :default_checkin_margin

      # How long (in minutes) is the checkin allowed to run for in in_progress
      # before it is considered failed.
      # @return [Integer, nil]
      attr_accessor :default_max_runtime

      # tz database style timezone string
      # @return [String, nil]
      attr_accessor :default_timezone
    end
  end
end

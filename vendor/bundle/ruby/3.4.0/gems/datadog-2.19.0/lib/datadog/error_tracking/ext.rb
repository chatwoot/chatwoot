# frozen_string_literal: true

module Datadog
  module ErrorTracking
    # Error Tracking constants
    module Ext
      ENV_HANDLED_ERRORS = 'DD_ERROR_TRACKING_HANDLED_ERRORS'
      ENV_HANDLED_ERRORS_INCLUDE = 'DD_ERROR_TRACKING_HANDLED_ERRORS_INCLUDE'
      HANDLED_ERRORS_ALL = 'all'
      HANDLED_ERRORS_USER = 'user'
      HANDLED_ERRORS_THIRD_PARTY = 'third_party'
      DEFAULT_HANDLED_ERRORS = nil
      VALID_HANDLED_ERRORS = [HANDLED_ERRORS_ALL, HANDLED_ERRORS_USER, HANDLED_ERRORS_THIRD_PARTY].freeze
      SPAN_EVENTS_HAS_EXCEPTION = '_dd.span_events.has_exception'
      RUBY_VERSION_WITH_RESCUE_EVENT = '3.3'
    end
  end
end

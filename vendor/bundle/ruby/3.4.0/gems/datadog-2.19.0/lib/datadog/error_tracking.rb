# frozen_string_literal: true

require_relative 'error_tracking/collector'
require_relative 'error_tracking/component'
require_relative 'error_tracking/configuration'
require_relative 'error_tracking/ext'
require_relative 'error_tracking/extensions'
require_relative 'error_tracking/filters'

module Datadog
  # Namespace for Datadog ErrorTracking.
  #
  # @api private
  module ErrorTracking
    # Expose ErrorTracking to global shared objects
    Extensions.activate!
  end
end

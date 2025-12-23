# frozen_string_literal: true

# Entrypoint file for auto instrumentation.
#
# This file's path is part of the @public_api.
require_relative '../datadog'
require_relative 'tracing/contrib/auto_instrument'

# DI is not loaded on Ruby 2.5 and JRuby
Datadog::DI::Contrib.load_now_or_later if defined?(Datadog::DI::Contrib)

Datadog::Profiling.start_if_enabled

module Datadog
  module AutoInstrument
    # Flag to determine if Auto Instrumentation was used
    LOADED = true
  end
end

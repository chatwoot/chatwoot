# frozen_string_literal: true

#
# Entrypoint file for single step instrumentation.
#
# This file's path is private. Do not reference this file.
#

module Datadog
  # This module handles conditional loading of single step auto-instrumentation,
  # which enables Datadog tracing and profiling features when available.
  module SingleStepInstrument
  end
end

begin
  require_relative 'auto_instrument'
  Datadog::SingleStepInstrument::LOADED = true
rescue StandardError, LoadError => e
  warn "Single step instrumentation failed: #{e.class}:#{e.message}\n\tSource:\n\t#{Array(e.backtrace).join("\n\t")}"
end

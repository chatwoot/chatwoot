# frozen_string_literal: true

require_relative "probe"

module Datadog
  module DI
    # Creates Probe instances from remote configuration payloads.
    #
    # Due to the dynamic instrumentation product evolving over time,
    # it is possible that the payload corresponds to a type of probe that the
    # current version of the library does not handle.
    # For now ArgumentError is raised in such cases (by ProbeBuilder or
    # Probe constructor), since generally DI is meant to rescue all exceptions
    # internally and not propagate any exceptions to applications.
    # A dedicated exception could be added in the future if there is a use case
    # for it.
    #
    # @api private
    module ProbeBuilder
      PROBE_TYPES = {
        'LOG_PROBE' => :log,
      }.freeze

      module_function def build_from_remote_config(config)
        # The validations here are not yet comprehensive.
        type = config.fetch('type')
        type_symbol = PROBE_TYPES[type] or raise ArgumentError, "Unrecognized probe type: #{type}"
        Probe.new(
          id: config.fetch("id"),
          type: type_symbol,
          file: config["where"]&.[]("sourceFile"),
          # Sometimes lines are sometimes received as an array of nil
          # for some reason.
          line_no: config["where"]&.[]("lines")&.compact&.map(&:to_i)&.first,
          type_name: config["where"]&.[]("typeName"),
          method_name: config["where"]&.[]("methodName"),
          template: config["template"],
          capture_snapshot: !!config["captureSnapshot"],
          max_capture_depth: config["capture"]&.[]("maxReferenceDepth"),
          max_capture_attribute_count: config["capture"]&.[]("maxFieldCount"),
          rate_limit: config["sampling"]&.[]("snapshotsPerSecond"),
        )
      rescue KeyError => exc
        raise ArgumentError, "Malformed remote configuration entry for probe: #{exc.class}: #{exc}: #{config}"
      end
    end
  end
end

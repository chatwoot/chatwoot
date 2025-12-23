# frozen_string_literal: true

# datadog-ci-rb versions 1.15.0 and lower require this file and guard
# the require with a rescue of StandardError. Unfortunately LoadError,
# which would be raised if the file is missing, is not a subclass of
# StandardError and thus would not be caught by the rescue.
# We provide this file with a dummy class in it to avoid exceptions
# in datadog-ci-rb until version 2.0 is released.
#
# Note that datadog-ci-rb patches telemetry transport to be "real" even when
# webmock is used; this patching won't work with datadog-ci-rb versions
# 1.15.0 and older and dd-trace-rb 2.16.0 and newer. There will be no
# errors/exceptions reported but telemetry events will not be sent.

module Datadog
  module Core
    module Telemetry
      module Http
        module Adapters
          class Net # rubocop:disable Lint/EmptyClass
          end
        end
      end
    end
  end
end

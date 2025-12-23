# frozen_string_literal: true

# Require 'datadog/di/preload' early in the application boot process to
# enable dynamic instrumentation for third-party libraries used by the
# application.

require_relative 'base'

# Code tracking is required for line probes to work; see the comments
# on the activate_tracking methods in di.rb for further details.
#
# Unlike di.rb which conditionally activates tracking only if the
# DD_DYNAMIC_INSTRUMENTATION_ENABLED environment variable is set, this file
# always activates tracking. This is because this file is explicitly loaded
# by customer applications for the purpose of enabling code tracking
# early in application boot process (i.e., before datadog library itself
# is loaded).
Datadog::DI.activate_tracking

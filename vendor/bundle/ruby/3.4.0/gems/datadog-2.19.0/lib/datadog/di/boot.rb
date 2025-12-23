# frozen_string_literal: true

require_relative 'logger'
require_relative 'base'
require_relative 'error'
require_relative 'code_tracker'
require_relative 'component'
require_relative 'instrumenter'
require_relative 'probe'
require_relative 'probe_builder'
require_relative 'probe_manager'
require_relative 'probe_notification_builder'
require_relative 'probe_notifier_worker'
require_relative 'redactor'
require_relative 'serializer'
require_relative 'transport/http'
require_relative 'utils'

if %w[1 true yes].include?(ENV['DD_DYNAMIC_INSTRUMENTATION_ENABLED']) # steep:ignore
  # For initial release of Dynamic Instrumentation, activate code tracking
  # only if DI is explicitly requested in the environment.
  # Code tracking is required for line probes to work; see the comments
  # above for the implementation of the method.
  #
  # If DI is enabled programmatically, the application can (and must,
  # for line probes to work) activate tracking in an initializer.
  # We seem to have Datadog.logger here already
  Datadog.logger.debug("di: activating code tracking")
  Datadog::DI.activate_tracking
end

require_relative 'contrib'

Datadog::DI::Contrib.load_now_or_later

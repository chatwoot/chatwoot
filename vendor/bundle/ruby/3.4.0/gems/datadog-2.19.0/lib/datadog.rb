# frozen_string_literal: true

# Load tracing
require_relative 'datadog/tracing'
require_relative 'datadog/tracing/contrib'

# Load other products (must follow tracing)
require_relative 'datadog/profiling'
require_relative 'datadog/appsec'
require_relative 'datadog/di'

# Line probes will not work on Ruby < 2.6 because of lack of :script_compiled
# trace point. Activate DI automatically on supported Ruby versions but
# always load its settings so that, for example, turning DI off when
# we are on Ruby 2.5 does not produce exceptions.
require_relative 'datadog/di/boot' if RUBY_VERSION >= '2.6' && RUBY_ENGINE != 'jruby'

require_relative 'datadog/error_tracking'
require_relative 'datadog/kit'

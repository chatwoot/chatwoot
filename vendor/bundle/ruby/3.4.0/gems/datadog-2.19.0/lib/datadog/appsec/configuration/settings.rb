# frozen_string_literal: true

require_relative '../../core/utils/duration'
require_relative '../sample_rate'

module Datadog
  module AppSec
    module Configuration
      # Settings
      module Settings
        # rubocop:disable Layout/LineLength
        DEFAULT_OBFUSCATOR_KEY_REGEX = '(?i)pass|pw(?:or)?d|secret|(?:api|private|public|access)[_-]?key|token|consumer[_-]?(?:id|key|secret)|sign(?:ed|ature)|bearer|authorization|jsessionid|phpsessid|asp\.net[_-]sessionid|sid|jwt'
        DEFAULT_OBFUSCATOR_VALUE_REGEX = '(?i)(?:p(?:ass)?w(?:or)?d|pass(?:[_-]?phrase)?|secret(?:[_-]?key)?|(?:(?:api|private|public|access)[_-]?)key(?:[_-]?id)?|(?:(?:auth|access|id|refresh)[_-]?)?token|consumer[_-]?(?:id|key|secret)|sign(?:ed|ature)?|auth(?:entication|orization)?|jsessionid|phpsessid|asp\.net(?:[_-]|-)sessionid|sid|jwt)(?:\s*=[^;]|"\s*:\s*"[^"]+")|bearer\s+[a-z0-9\._\-]+|token:[a-z0-9]{13}|gh[opsu]_[0-9a-zA-Z]{36}|ey[I-L][\w=-]+\.ey[I-L][\w=-]+(?:\.[\w.+\/=-]+)?|[\-]{5}BEGIN[a-z\s]+PRIVATE\sKEY[\-]{5}[^\-]+[\-]{5}END[a-z\s]+PRIVATE\sKEY|ssh-rsa\s*[a-z0-9\/\.+]{100,}'
        # rubocop:enable Layout/LineLength

        DISABLED_AUTO_USER_INSTRUMENTATION_MODE = 'disabled'
        ANONYMIZATION_AUTO_USER_INSTRUMENTATION_MODE = 'anonymization'
        IDENTIFICATION_AUTO_USER_INSTRUMENTATION_MODE = 'identification'
        AUTO_USER_INSTRUMENTATION_MODES = [
          DISABLED_AUTO_USER_INSTRUMENTATION_MODE,
          ANONYMIZATION_AUTO_USER_INSTRUMENTATION_MODE,
          IDENTIFICATION_AUTO_USER_INSTRUMENTATION_MODE
        ].freeze
        AUTO_USER_INSTRUMENTATION_MODES_ALIASES = {
          'ident' => IDENTIFICATION_AUTO_USER_INSTRUMENTATION_MODE,
          'anon' => ANONYMIZATION_AUTO_USER_INSTRUMENTATION_MODE,
        }.freeze

        # NOTE: These two constants are deprecated
        SAFE_TRACK_USER_EVENTS_MODE = 'safe'
        EXTENDED_TRACK_USER_EVENTS_MODE = 'extended'
        APPSEC_VALID_TRACK_USER_EVENTS_MODE = [
          SAFE_TRACK_USER_EVENTS_MODE, EXTENDED_TRACK_USER_EVENTS_MODE
        ].freeze
        APPSEC_VALID_TRACK_USER_EVENTS_ENABLED_VALUES = ['1', 'true'].concat(
          APPSEC_VALID_TRACK_USER_EVENTS_MODE
        ).freeze

        def self.extended(base)
          base = base.singleton_class unless base.is_a?(Class)
          add_settings!(base)
        end

        # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/BlockLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        def self.add_settings!(base)
          base.class_eval do
            settings :appsec do
              option :enabled do |o|
                o.type :bool
                o.env 'DD_APPSEC_ENABLED'
                o.default false
              end

              define_method(:instrument) do |integration_name|
                if enabled
                  registered_integration = Datadog::AppSec::Contrib::Integration.registry[integration_name]
                  if registered_integration
                    klass = registered_integration.klass
                    if klass.loaded? && klass.compatible?
                      instance = klass.new
                      instance.patcher.patch unless instance.patcher.patched?
                    end
                  end
                end
              end

              # RASP or Runtime Application Self-Protection
              # is a collection of techniques and heuristics aimed at detecting malicious inputs and preventing
              # any potential side-effects on the application resulting from the use of said malicious inputs.
              option :rasp_enabled do |o|
                o.type :bool, nilable: true
                o.env 'DD_APPSEC_RASP_ENABLED'
                o.default true
              end

              option :ruleset do |o|
                o.env 'DD_APPSEC_RULES'
                o.default :recommended
              end

              option :ip_passlist do |o|
                o.default []

                o.setter do |value|
                  next value if value.nil? || value.empty?

                  Datadog::Core.log_deprecation(disallowed_next_major: false) do
                    'The ip_passlist setting is deprecated and will be removed in the next release. ' \
                    'Please migrate this configuration to your service settings via the Datadog UI'
                  end

                  value
                end
              end

              option :ip_denylist do |o|
                o.type :array
                o.default []

                o.setter do |value|
                  next value if value.nil? || value.empty?

                  Datadog::Core.log_deprecation(disallowed_next_major: false) do
                    'The ip_denylist setting is deprecated and will be removed in the next release. ' \
                    'Please migrate this configuration to your service settings via the Datadog UI'
                  end

                  value
                end
              end

              option :user_id_denylist do |o|
                o.type :array
                o.default []

                o.setter do |value|
                  next value if value.nil? || value.empty?

                  Datadog::Core.log_deprecation(disallowed_next_major: false) do
                    'The user_id_denylist setting is deprecated and will be removed in the next release. ' \
                    'Please migrate this configuration to your service settings via the Datadog UI'
                  end

                  value
                end
              end

              option :waf_timeout do |o|
                o.env 'DD_APPSEC_WAF_TIMEOUT' # us
                o.default 5_000
                o.setter do |v|
                  Datadog::Core::Utils::Duration.call(v.to_s, base: :us)
                end
              end

              option :waf_debug do |o|
                o.env 'DD_APPSEC_WAF_DEBUG'
                o.default false
                o.type :bool
              end

              option :trace_rate_limit do |o|
                o.type :int
                o.env 'DD_APPSEC_TRACE_RATE_LIMIT' # trace/s
                o.default 100
              end

              option :obfuscator_key_regex do |o|
                o.type :string
                o.env 'DD_APPSEC_OBFUSCATION_PARAMETER_KEY_REGEXP'
                o.default DEFAULT_OBFUSCATOR_KEY_REGEX
              end

              option :obfuscator_value_regex do |o|
                o.type :string
                o.env 'DD_APPSEC_OBFUSCATION_PARAMETER_VALUE_REGEXP'
                o.default DEFAULT_OBFUSCATOR_VALUE_REGEX
              end

              settings :block do
                settings :templates do
                  option :html do |o|
                    o.env 'DD_APPSEC_HTTP_BLOCKED_TEMPLATE_HTML'
                    o.type :string, nilable: true
                    o.setter do |value|
                      if value
                        unless File.exist?(value)
                          raise(ArgumentError,
                            "appsec.templates.html: file not found: #{value}")
                        end

                        File.binread(value) || ''
                      end
                    end
                  end

                  option :json do |o|
                    o.env 'DD_APPSEC_HTTP_BLOCKED_TEMPLATE_JSON'
                    o.type :string, nilable: true
                    o.setter do |value|
                      if value
                        unless File.exist?(value)
                          raise(ArgumentError,
                            "appsec.templates.json: file not found: #{value}")
                        end

                        File.binread(value) || ''
                      end
                    end
                  end

                  option :text do |o|
                    o.env 'DD_APPSEC_HTTP_BLOCKED_TEMPLATE_TEXT'
                    o.type :string, nilable: true
                    o.setter do |value|
                      if value
                        unless File.exist?(value)
                          raise(ArgumentError,
                            "appsec.templates.text: file not found: #{value}")
                        end

                        File.binread(value) || ''
                      end
                    end
                  end
                end
              end

              settings :stack_trace do
                option :enabled do |o|
                  o.type :bool
                  o.env 'DD_APPSEC_STACK_TRACE_ENABLED'
                  o.default true
                end

                # The maximum number of stack trace frames to collect for each stack trace.
                #
                # If the stack trace exceeds this limit, the frames are dropped from the middle of the stack trace:
                # 75% of the frames are kept from the top of the stack trace and 25% from the bottom
                # (this percentage is also configurable).
                #
                # Minimum value is 10.
                # Set to zero if you don't want any frames to be dropped.
                #
                # Default value is 32
                option :max_depth do |o|
                  o.type :int
                  o.env 'DD_APPSEC_MAX_STACK_TRACE_DEPTH'
                  o.default 32

                  o.setter do |value|
                    value = 0 if value < 0
                    value
                  end
                end

                # The percentage of frames to keep from the top of the stack trace.
                #
                # Default value is 75
                option :top_percentage do |o|
                  o.type :int
                  o.env 'DD_APPSEC_MAX_STACK_TRACE_DEPTH_TOP_PERCENT'
                  o.default 75

                  o.setter do |value|
                    value = 100 if value > 100
                    value = 0 if value.negative?
                    value
                  end
                end

                # Maximum number of stack traces to collect per span.
                #
                # Set to zero if you want to collect all stack traces.
                #
                # Default value is 2
                option :max_stack_traces do |o|
                  o.type :int
                  o.env 'DD_APPSEC_MAX_STACK_TRACES'
                  o.default 2

                  o.setter do |value|
                    value = 0 if value < 0
                    value
                  end
                end
              end

              settings :auto_user_instrumentation do
                define_method(:enabled?) { get_option(:mode) != DISABLED_AUTO_USER_INSTRUMENTATION_MODE }

                option :mode do |o|
                  o.type :string
                  o.env 'DD_APPSEC_AUTO_USER_INSTRUMENTATION_MODE'
                  o.default IDENTIFICATION_AUTO_USER_INSTRUMENTATION_MODE
                  o.setter do |value|
                    mode = AUTO_USER_INSTRUMENTATION_MODES_ALIASES.fetch(value, value)
                    next mode if AUTO_USER_INSTRUMENTATION_MODES.include?(mode)

                    Datadog.logger.warn(
                      'The appsec.auto_user_instrumentation.mode value provided is not supported. ' \
                      "Supported values are: #{AUTO_USER_INSTRUMENTATION_MODES.join(" | ")}. " \
                      "Using value: #{DISABLED_AUTO_USER_INSTRUMENTATION_MODE}."
                    )

                    DISABLED_AUTO_USER_INSTRUMENTATION_MODE
                  end
                end
              end

              # DEV-3.0: Remove `track_user_events.enabled` and `track_user_events.mode` options
              settings :track_user_events do
                option :enabled do |o|
                  o.default true
                  o.type :bool
                  o.env 'DD_APPSEC_AUTOMATED_USER_EVENTS_TRACKING'
                  o.env_parser do |env_value|
                    if env_value == 'disabled'
                      false
                    else
                      APPSEC_VALID_TRACK_USER_EVENTS_ENABLED_VALUES.include?(env_value.strip.downcase)
                    end
                  end
                  o.after_set do |_, _, precedence|
                    unless precedence == Datadog::Core::Configuration::Option::Precedence::DEFAULT
                      Core.log_deprecation(key: :appsec_track_user_events_enabled) do
                        'The appsec.track_user_events.enabled setting is deprecated. ' \
                        'Please remove it from your Datadog.configure block and use ' \
                        'appsec.auto_user_instrumentation.mode instead.'
                      end
                    end
                  end
                end

                option :mode do |o|
                  o.type :string
                  o.env 'DD_APPSEC_AUTOMATED_USER_EVENTS_TRACKING'
                  o.default SAFE_TRACK_USER_EVENTS_MODE
                  o.setter do |v|
                    if APPSEC_VALID_TRACK_USER_EVENTS_MODE.include?(v)
                      v
                    elsif v == 'disabled'
                      SAFE_TRACK_USER_EVENTS_MODE
                    else
                      Datadog.logger.warn(
                        'The appsec.track_user_events.mode value provided is not supported.' \
                        "Supported values are: #{APPSEC_VALID_TRACK_USER_EVENTS_MODE.join(" | ")}." \
                        "Using default value: #{SAFE_TRACK_USER_EVENTS_MODE}."
                      )

                      SAFE_TRACK_USER_EVENTS_MODE
                    end
                  end
                  o.after_set do |_, _, precedence|
                    unless precedence == Datadog::Core::Configuration::Option::Precedence::DEFAULT
                      Core.log_deprecation(key: :appsec_track_user_events_mode) do
                        'The appsec.track_user_events.mode setting is deprecated. ' \
                        'Please remove it from your Datadog.configure block and use ' \
                        'appsec.auto_user_instrumentation.mode instead.'
                      end
                    end
                  end
                end
              end

              settings :api_security do
                define_method(:enabled?) { get_option(:enabled) }

                option :enabled do |o|
                  o.type :bool
                  o.env 'DD_API_SECURITY_ENABLED'
                  o.default true
                end

                # NOTE: Unfortunately, we have to go with Float due to other libs
                #       setup, even tho we don't plan to support sub-second delays.
                #
                # WARNING: The value will be converted to Integer.
                option :sample_delay do |o|
                  o.type :float
                  o.env 'DD_API_SECURITY_SAMPLE_DELAY'
                  o.default 30
                  o.setter do |value|
                    value.to_i
                  end
                end

                # DEV-3.0: Remove `api_security.sample_rate` option
                option :sample_rate do |o|
                  o.type :float
                  o.env 'DD_API_SECURITY_REQUEST_SAMPLE_RATE'
                  o.default 0.1
                  o.setter do |value|
                    value = 1 if value > 1
                    SampleRate.new(value)
                  end
                  o.after_set do |_, _, precedence|
                    next if precedence == Datadog::Core::Configuration::Option::Precedence::DEFAULT

                    Core.log_deprecation(key: :appsec_api_security_sample_rate) do
                      'The appsec.api_security.sample_rate setting is deprecated. ' \
                      'Please remove it from your Datadog.configure block and use ' \
                      'appsec.api_security.sample_delay instead.'
                    end
                  end
                end
              end

              option :sca_enabled do |o|
                o.type :bool, nilable: true
                o.env 'DD_APPSEC_SCA_ENABLED'
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize,Metrics/MethodLength,Metrics/BlockLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      end
    end
  end
end

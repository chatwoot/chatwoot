# frozen_string_literal: true

module Datadog
  module DI
    module Configuration
      # Settings
      module Settings
        def self.extended(base)
          base = base.singleton_class unless base.is_a?(Class)
          add_settings!(base)
        end

        def self.add_settings!(base)
          base.class_eval do
            settings :dynamic_instrumentation do
              option :enabled do |o|
                o.type :bool
                # The environment variable has an "internal" prefix so that
                # any customers that have the "proper" environment variable
                # turned on (i.e. DD_DYNAMIC_INSTRUMENTATION_ENABLED)
                # do not enable Ruby DI until the latter is ready for
                # customer testing.
                o.env "DD_DYNAMIC_INSTRUMENTATION_ENABLED"
                o.default false
              end

              # An array of variable and key names to redact in addition to
              # the built-in list of identifiers.
              #
              # The names will be normalized by removing the following
              # symbols: _, -, @, $, and then matched to the complete
              # variable or key name while ignoring the case.
              # For example, specifying pass_word will match password and
              # PASSWORD, and specifying PASSWORD will match pass_word.
              # Note that, while the at sign (@) is used in Ruby to refer
              # to instance variables, it does not have any significance
              # for this setting (and is removed before matching identifiers).
              option :redacted_identifiers do |o|
                o.env "DD_DYNAMIC_INSTRUMENTATION_REDACTED_IDENTIFIERS"
                o.env_parser do |value|
                  value&.split(",")&.map(&:strip)
                end

                o.type :array
                o.default []
              end

              # An array of class names, values of which will be redacted from
              # dynamic instrumentation snapshots. Example: FooClass.
              # If a name is suffixed by '*', it becomes a wildcard and
              # instances of any class whose name begins with the specified
              # prefix will be redacted (example: Foo*).
              #
              # The names must all be fully-qualified, if any prefix of a
              # class name is configured to be redacted, the value will be
              # subject to redaction. For example, if Foo* is in the
              # redacted class name list, instances of Foo, FooBar,
              # Foo::Bar are all subject to redaction, but Bar::Foo will
              # not be subject to redaction.
              #
              # Leading double-colon is permitted but has no effect,
              # because the names are always considered to be fully-qualified.
              # For example, adding ::Foo to the list will redact instances
              # of Foo.
              #
              # Trailing colons should not be used because they will trigger
              # exact match behavior but Ruby class names do not have
              # trailing colons. For example, Foo:: will not cause anything
              # to be redacted. Use Foo::* to redact all classes under
              # the Foo module.
              option :redacted_type_names do |o|
                o.env "DD_DYNAMIC_INSTRUMENTATION_REDACTED_TYPES"
                o.env_parser do |value|
                  value&.split(",")&.map(&:strip)
                end

                o.type :array
                o.default []
              end

              # Maximum number of object or collection traversals that
              # will be permitted when serializing captured values.
              option :max_capture_depth do |o|
                o.type :int
                o.default 3
              end

              # Maximum number of collection (Array and Hash) elements
              # that will be captured. Arrays and hashes that have more
              # elements will be truncated to this many elements.
              option :max_capture_collection_size do |o|
                o.type :int
                o.default 100
              end

              # Strings longer than this length will be truncated to this
              # length in dynamic instrumentation snapshots.
              #
              # Note that while all values are stringified during
              # serialization, only values which are originally instances
              # of the String class are subject to this length limit.
              option :max_capture_string_length do |o|
                o.type :int
                o.default 255
              end

              # Maximim number of attributes that will be captured for
              # a single non-primitive value.
              option :max_capture_attribute_count do |o|
                o.type :int
                o.default 20
              end

              # Settings in the 'internal' group are for internal Datadog
              # use only, and are needed to test dynamic instrumentation or
              # experiment with features not released to customers.
              settings :internal do
                # This option instructs dynamic instrumentation to use
                # untargeted trace points when installing line probes and
                # code tracking is not active.
                # WARNING: untargeted trace points carry a massive performance
                # penalty for the entire file in which a line probe is placed.
                #
                # If this option is set to false, which is the default,
                # dynamic instrumentation will add probes that reference
                # unknown files to the list of pending probes, and when
                # the respective files are loaded, the line probes will be
                # installed using targeted trace points. If the file in
                # question is already loaded when the probe is received
                # (for example, it is in a third-party library loaded during
                # application boot), and code tracking was not active when
                # the file was loaded, such files will not be instrumentable
                # via line probes.
                #
                # If this option is set to true, dynamic instrumentation will
                # install untargeted trace points for all line probes,
                # regardless of whether the referenced file is loaded.
                # This permits instrumenting code which was loaded prior to
                # code tracking being activated and instrumenting lines when
                # code tracking is not activated at all. However, untargeted
                # trace points are extremely slow and will greatly degrade
                # performance of *all* code executed while they are installed,
                # not just the instrumentation target.
                option :untargeted_trace_points do |o|
                  o.type :bool
                  o.default false
                end

                # If true, all of the catch-all rescue blocks in DI
                # will propagate the exceptions onward.
                # WARNING: for internal Datadog use only - this will break
                # the DI product and potentially the library in general in
                # a multitude of ways, cause resource leakage, permanent
                # performance decreases, etc.
                option :propagate_all_exceptions do |o|
                  o.type :bool
                  o.default false
                end

                # Minimum interval, in seconds, between probe status and
                # snapshot submissions to the agent. Probe notifier worker will
                # batch together payloads submitted during each interval.
                # A longer interval reduces the overhead imposed by dynamic
                # instrumentation on the application, but also increases the
                # time when application code cannot run (when the batches are
                # being sent out by the probe notifier worker) and creates a
                # possibility of dropping payloads if the queue gets too long.
                option :min_send_interval do |o|
                  o.type :float
                  o.default 3
                end

                # Number of snapshots that can be stored in the probe
                # notifier worker queue. Larger capacity runs the risk of
                # creating snapshots that exceed the agent's request size
                # limit. Smaller capacity increases the risk of dropping
                # snapshots.
                option :snapshot_queue_capacity do |o|
                  o.type :int
                  o.default 100
                end

                # Enable dynamic instrumentation in development environments.
                # Currently DI does not fully implement support for code
                # unloading and reloading, and is not supported in
                # non-production environments.
                option :development do |o|
                  o.type :bool
                  o.default false
                end

                # Enable logging of dynamic instrumentation activity.
                # This is quite verbose.
                option :trace_logging do |o|
                  o.type :bool
                  o.default false

                  # Use the same environment variable as the rest of
                  # dd-trace-rb logging for now. Could change to a
                  # dedicated environment variable in the future but
                  # will likely need a way to turn on remote config
                  # debugging (since DI uses RC for configuration).
                  o.env 'DD_TRACE_DEBUG'
                end
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Rails
        # Instruments the `bin/rails runner` command.
        # This command executes the provided code with the host Rails application loaded.
        # The command can be either:
        # * `-`: for code provided through the STDIN.
        # * File path: for code provided through a local file.
        # * `inline code`: for code provided directly as a command line argument.
        #
        # The difficulty in instrumenting the Rails Runner is that
        # the Rails application (and as a consequence the Datadog tracing library)
        # is loaded very late in the runner execution.
        # The Rails application is loaded inside the same method the method
        # that directly executes the code the user wants the runner to execute:
        #
        # ```ruby
        # def perform(code_or_file = nil, *command_argv)
        #   boot_application! # Loads the Rails and Datadog
        #
        #   if code_or_file == "-"
        #     eval($stdin.read, TOPLEVEL_BINDING, "stdin") # Calls the user code for this Runner
        #   # ...
        # ```
        #
        # This means that there's no time to instrument the calling method, `perform`, which
        # would be ideal. Instead, we resort to instrumenting `eval` and `load`, but
        # only for calls from the `Rails::Command::RunnerCommand` class.
        #
        # @see https://guides.rubyonrails.org/v6.1/command_line.html#bin-rails-runner
        module Runner
          # Limit the maximum size of the source code captured in the source tag.
          MAX_TAG_VALUE_SIZE = 4096
          private_constant :MAX_TAG_VALUE_SIZE

          # Instruments the `Kernel.eval` method, but only for the
          # `Rails::Command::RunnerCommand` class.
          def eval(*args)
            source = args[0]

            if args[2] == 'stdin'
              name = Ext::SPAN_RUNNER_STDIN
              operation = Ext::TAG_OPERATION_STDIN
            else
              name = Ext::SPAN_RUNNER_INLINE
              operation = Ext::TAG_OPERATION_INLINE
            end

            Tracing.trace(
              name,
              service: Datadog.configuration.tracing[:rails][:service_name],
              tags: {
                Tracing::Metadata::Ext::TAG_COMPONENT => Ext::TAG_COMPONENT,
                Tracing::Metadata::Ext::TAG_OPERATION => operation,
              }
            ) do |span|
              if source
                span.set_tag(
                  Ext::TAG_RUNNER_SOURCE,
                  Core::Utils.truncate(source, MAX_TAG_VALUE_SIZE)
                )
              end
              Contrib::Analytics.set_rate!(span, Datadog.configuration.tracing[:rails])

              super
            end
          end

          def self.prepend(base)
            base.const_set(:Kernel, Kernel)
          end

          # Instruments the `Kernel.load` method, but only for the
          # `Rails::Command::RunnerCommand` class.
          module Kernel
            def self.load(file, wrap = true)
              name = Ext::SPAN_RUNNER_FILE
              resource = file
              operation = Ext::TAG_OPERATION_FILE

              begin
                # Reads one more byte than the limit to allow us to check if the source exceeds the limit.
                source = File.read(file, MAX_TAG_VALUE_SIZE + 1)
              rescue => e
                Datadog.logger.debug("Failed to read file '#{file}' for Rails runner: #{e.message}")
              end

              Tracing.trace(
                name,
                service: Datadog.configuration.tracing[:rails][:service_name],
                resource: resource,
                tags: {
                  Tracing::Metadata::Ext::TAG_COMPONENT => Ext::TAG_COMPONENT,
                  Tracing::Metadata::Ext::TAG_OPERATION => operation,
                }
              ) do |span|
                if source
                  span.set_tag(
                    Ext::TAG_RUNNER_SOURCE,
                    Core::Utils.truncate(source, MAX_TAG_VALUE_SIZE)
                  )
                end
                Contrib::Analytics.set_rate!(span, Datadog.configuration.tracing[:rails])

                super
              end
            end
          end
        end
      end
    end
  end
end

module RSpec
  module Rails
    # @api public
    # Container class for system tests
    module SystemExampleGroup
      extend ActiveSupport::Concern
      include RSpec::Rails::RailsExampleGroup
      include RSpec::Rails::Matchers::RedirectTo
      include RSpec::Rails::Matchers::RenderTemplate
      include ActionDispatch::Integration::Runner
      include ActionDispatch::Assertions
      include ActionController::TemplateAssertions

      # Special characters to translate into underscores for #method_name
      CHARS_TO_TRANSLATE = ['/', '.', ':', ',', "'", '"', " "].freeze

      # @private
      module BlowAwayTeardownHooks
        # @private
        def before_teardown
        end

        # @private
        def after_teardown
        end
      end

      # for the SystemTesting Screenshot situation
      def passed?
        return false if RSpec.current_example.exception
        return true unless defined?(::RSpec::Expectations::FailureAggregator)

        failure_notifier = ::RSpec::Support.failure_notifier
        return true unless failure_notifier.is_a?(::RSpec::Expectations::FailureAggregator)

        failure_notifier.failures.empty? && failure_notifier.other_errors.empty?
      end

      # @private
      def method_name
        @method_name ||= [
          self.class.name.underscore,
          RSpec.current_example.description.underscore
        ].join("_").tr(CHARS_TO_TRANSLATE.join, "_").byteslice(0...200).scrub("") + "_#{rand(1000)}"
      end

      if ::Rails::VERSION::STRING.to_f >= 7.1
        # @private
        # Allows failure screenshot to work whilst not exposing metadata
        class SuppressRailsScreenshotMetadata
          def initialize
            @example_data = {}
          end

          def [](key)
            if @example_data.key?(key)
              @example_data[key]
            else
              raise_wrong_scope_error
            end
          end

          def []=(key, value)
            if key == :failure_screenshot_path
              @example_data[key] = value
            else
              raise_wrong_scope_error
            end
          end

          def method_missing(_name, *_args, &_block)
            raise_wrong_scope_error
          end

          private

          def raise_wrong_scope_error
            raise RSpec::Core::ExampleGroup::WrongScopeError,
                  "`metadata` is not available from within an example " \
                  "(e.g. an `it` block) or from constructs that run in the " \
                  "scope of an example (e.g. `before`, `let`, etc). It is " \
                  "only available on an example group (e.g. a `describe` or "\
                  "`context` block)"
          end
        end

        # @private
        def metadata
          @metadata ||= SuppressRailsScreenshotMetadata.new
        end
      end

      # Delegates to `Rails.application`.
      def app
        ::Rails.application
      end

      # Default driver to assign if none specified.
      DEFAULT_DRIVER =
        if ::Rails::VERSION::STRING.to_f >= 7.2
          :selenium_chrome_headless
        else
          :selenium
        end

      included do |other|
        ActiveSupport.on_load(:action_dispatch_system_test_case) do
          ActionDispatch::SystemTesting::Server.silence_puma = true
        end

        require 'action_dispatch/system_test_case'

        begin
          require 'capybara'
        rescue LoadError => e
          abort """
            LoadError: #{e.message}
            System test integration has a hard
            dependency on a webserver and `capybara`, please add capybara to
            your Gemfile and configure a webserver (e.g. `Capybara.server =
            :puma`) before attempting to use system specs.
          """.gsub(/\s+/, ' ').strip
        end

        original_before_teardown =
          ::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown.instance_method(:before_teardown)

        original_after_teardown =
          ::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown.instance_method(:after_teardown)

        other.include ::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown
        other.include ::ActionDispatch::SystemTesting::TestHelpers::ScreenshotHelper
        other.include BlowAwayTeardownHooks

        attr_reader :driver

        if ActionDispatch::SystemTesting::Server.respond_to?(:silence_puma=)
          ActionDispatch::SystemTesting::Server.silence_puma = true
        end

        def initialize(*args, &blk)
          super(*args, &blk)
          @driver = nil

          self.class.before do
            # A user may have already set the driver, so only default if driver
            # is not set
            driven_by(DEFAULT_DRIVER) unless @driver
          end
        end

        def driven_by(driver, **driver_options, &blk)
          @driver = ::ActionDispatch::SystemTestCase.driven_by(driver, **driver_options, &blk).tap(&:use)
        end

        before do
          @routes = ::Rails.application.routes
        end

        after do
          orig_stdout = $stdout
          $stdout = StringIO.new
          begin
            original_before_teardown.bind(self).call
          ensure
            myio = $stdout
            myio.rewind
            RSpec.current_example.metadata[:extra_failure_lines] = myio.readlines
            $stdout = orig_stdout
          end
        end

        around do |example|
          example.run
          original_after_teardown.bind(self).call
        end
      end
    end
  end
end

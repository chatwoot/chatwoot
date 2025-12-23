# rubocop: disable Metrics/ModuleLength
module RSpec
  module Rails
    # Fake class to document RSpec Rails configuration options. In practice,
    # these are dynamically added to the normal RSpec configuration object.
    class Configuration
      # @!method infer_spec_type_from_file_location!
      # Automatically tag specs in conventional directories with matching `type`
      # metadata so that they have relevant helpers available to them. See
      # `RSpec::Rails::DIRECTORY_MAPPINGS` for details on which metadata is
      # applied to each directory.

      # @!method render_views=(val)
      #
      # When set to `true`, controller specs will render the relevant view as
      # well. Defaults to `false`.

      # @!method render_views(val)
      # Enables view rendering for controllers specs.

      # @!method render_views?
      # Reader for currently value of `render_views` setting.
    end

    # Mappings used by `infer_spec_type_from_file_location!`.
    #
    # @api private
    DIRECTORY_MAPPINGS = {
      channel: %w[spec channels],
      controller: %w[spec controllers],
      generator: %w[spec generator],
      helper: %w[spec helpers],
      job: %w[spec jobs],
      mailer: %w[spec mailers],
      model: %w[spec models],
      request: %w[spec (requests|integration|api)],
      routing: %w[spec routing],
      view: %w[spec views],
      feature: %w[spec features],
      system: %w[spec system],
      mailbox: %w[spec mailboxes]
    }

    # Sets up the different example group modules for the different spec types
    #
    # @api private
    def self.add_test_type_configurations(config)
      config.include RSpec::Rails::ControllerExampleGroup, type: :controller
      config.include RSpec::Rails::HelperExampleGroup,     type: :helper
      config.include RSpec::Rails::ModelExampleGroup,      type: :model
      config.include RSpec::Rails::RequestExampleGroup,    type: :request
      config.include RSpec::Rails::RoutingExampleGroup,    type: :routing
      config.include RSpec::Rails::ViewExampleGroup,       type: :view
      config.include RSpec::Rails::FeatureExampleGroup,    type: :feature
      config.include RSpec::Rails::Matchers
      config.include RSpec::Rails::SystemExampleGroup, type: :system
    end

    # @private
    def self.initialize_configuration(config) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize,Metrics/PerceivedComplexity
      config.backtrace_exclusion_patterns << /vendor\//
      config.backtrace_exclusion_patterns << %r{lib/rspec/rails}

      # controller settings
      config.add_setting :infer_base_class_for_anonymous_controllers, default: true

      # fixture support
      config.add_setting :use_active_record, default: true
      config.add_setting :use_transactional_fixtures, alias_with: :use_transactional_examples
      config.add_setting :use_instantiated_fixtures
      config.add_setting :global_fixtures

      if ::Rails::VERSION::STRING < "7.1.0"
        config.add_setting :fixture_path
      else
        config.add_setting :fixture_paths
      end

      config.include RSpec::Rails::FixtureSupport, :use_fixtures

      # We'll need to create a deprecated module in order to properly report to
      # gems / projects which are relying on this being loaded globally.
      #
      # See rspec/rspec-rails#1355 for history
      #
      # @deprecated Include `RSpec::Rails::RailsExampleGroup` or
      #   `RSpec::Rails::FixtureSupport` directly instead
      config.include RSpec::Rails::FixtureSupport

      config.add_setting :file_fixture_path, default: 'spec/fixtures/files'
      config.include RSpec::Rails::FileFixtureSupport

      # Add support for fixture_path on fixture_file_upload
      config.include RSpec::Rails::FixtureFileUploadSupport

      # This allows us to expose `render_views` as a config option even though it
      # breaks the convention of other options by using `render_views` as a
      # command (i.e. `render_views = true`), where it would normally be used
      # as a getter. This makes it easier for rspec-rails users because we use
      # `render_views` directly in example groups, so this aligns the two APIs,
      # but requires this workaround:
      config.add_setting :rendering_views, default: false

      config.instance_exec do
        def render_views=(val)
          self.rendering_views = val
        end

        def render_views
          self.rendering_views = true
        end

        def render_views?
          rendering_views?
        end

        undef :rendering_views? if respond_to?(:rendering_views?)
        def rendering_views?
          !!rendering_views
        end

        # Define boolean predicates rather than relying on rspec-core due
        # to the bug fix in rspec/rspec-core#2736, note some of these
        # predicates are a bit nonsensical, but they exist for backwards
        # compatibility, we can tidy these up in `rspec-rails` 5.
        undef :fixture_path? if respond_to?(:fixture_path?)
        def fixture_path?
          !!fixture_path
        end

        undef :global_fixtures? if respond_to?(:global_fixtures?)
        def global_fixtures?
          !!global_fixtures
        end

        undef :infer_base_class_for_anonymous_controllers? if respond_to?(:infer_base_class_for_anonymous_controllers?)
        def infer_base_class_for_anonymous_controllers?
          !!infer_base_class_for_anonymous_controllers
        end

        undef :use_instantiated_fixtures? if respond_to?(:use_instantiated_fixtures?)
        def use_instantiated_fixtures?
          !!use_instantiated_fixtures
        end

        undef :use_transactional_fixtures? if respond_to?(:use_transactional_fixtures?)
        def use_transactional_fixtures?
          !!use_transactional_fixtures
        end

        def infer_spec_type_from_file_location!
          DIRECTORY_MAPPINGS.each do |type, dir_parts|
            escaped_path = Regexp.compile(dir_parts.join('[\\\/]') + '[\\\/]')
            define_derived_metadata(file_path: escaped_path) do |metadata|
              metadata[:type] ||= type
            end
          end
        end

        # Adds exclusion filters for gems included with Rails
        def filter_rails_from_backtrace!
          filter_gems_from_backtrace "actionmailer", "actionpack", "actionview"
          filter_gems_from_backtrace "activemodel", "activerecord",
                                     "activesupport", "activejob"
        end

        # @deprecated TestFixtures#fixture_path is deprecated and will be removed in Rails 7.2
        if ::Rails::VERSION::STRING >= "7.1.0"
          def fixture_path
            RSpec.deprecate(
              "config.fixture_path",
              replacement: "config.fixture_paths",
              message: "Rails 7.1 has deprecated the singular fixture_path in favour of an array." \
              "You should migrate to plural:"
            )
            fixture_paths&.first
          end

          def fixture_path=(path)
            RSpec.deprecate(
              "config.fixture_path = #{path.inspect}",
              replacement: "config.fixture_paths = [#{path.inspect}]",
              message: "Rails 7.1 has deprecated the singular fixture_path in favour of an array." \
              "You should migrate to plural:"
            )
            self.fixture_paths = Array(path)
          end
        end
      end

      add_test_type_configurations(config)

      if defined?(::Rails::Controller::Testing)
        [:controller, :view, :request].each do |type|
          config.include ::Rails::Controller::Testing::TestProcess, type: type
          config.include ::Rails::Controller::Testing::TemplateAssertions, type: type
          config.include ::Rails::Controller::Testing::Integration, type: type
        end
      end

      if RSpec::Rails::FeatureCheck.has_action_mailer?
        config.include RSpec::Rails::MailerExampleGroup, type: :mailer
        config.after { ActionMailer::Base.deliveries.clear }
      end

      if RSpec::Rails::FeatureCheck.has_active_job?
        config.include RSpec::Rails::JobExampleGroup, type: :job
      end

      if RSpec::Rails::FeatureCheck.has_action_cable_testing?
        config.include RSpec::Rails::ChannelExampleGroup, type: :channel
      end

      if RSpec::Rails::FeatureCheck.has_action_mailbox?
        config.include RSpec::Rails::MailboxExampleGroup, type: :mailbox
      end
    end

    initialize_configuration RSpec.configuration
  end
end
# rubocop: enable Metrics/ModuleLength

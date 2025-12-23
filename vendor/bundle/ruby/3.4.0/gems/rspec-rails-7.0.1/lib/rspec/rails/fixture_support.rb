module RSpec
  module Rails
    # @private
    module FixtureSupport
      if defined?(ActiveRecord::TestFixtures)
        extend ActiveSupport::Concern
        include RSpec::Rails::SetupAndTeardownAdapter
        include RSpec::Rails::MinitestLifecycleAdapter
        include RSpec::Rails::MinitestAssertionAdapter
        include ActiveRecord::TestFixtures

        # @private prevent ActiveSupport::TestFixtures to start a DB transaction.
        # Monkey patched to avoid collisions with 'let(:name)' since Rails 6.1
        def run_in_transaction?
          current_example_name = (RSpec.current_example && RSpec.current_example.metadata[:description])
          use_transactional_tests && !self.class.uses_transaction?(current_example_name)
        end

        included do
          if RSpec.configuration.use_active_record?
            include Fixtures

            # TestFixtures#fixture_path is deprecated and will be removed in Rails 7.2
            if respond_to?(:fixture_paths=)
              self.fixture_paths = RSpec.configuration.fixture_paths
            else
              self.fixture_path = RSpec.configuration.fixture_path
            end

            self.use_transactional_tests = RSpec.configuration.use_transactional_fixtures
            self.use_instantiated_fixtures = RSpec.configuration.use_instantiated_fixtures

            fixtures RSpec.configuration.global_fixtures if RSpec.configuration.global_fixtures
          end
        end

        module Fixtures
          extend ActiveSupport::Concern

          # rubocop:disable Metrics/BlockLength
          class_methods do
            if ::Rails.version.to_f >= 7.1
              def fixtures(*args)
                super.tap do
                  fixture_sets.each_pair do |method_name, fixture_name|
                    proxy_method_warning_if_called_in_before_context_scope(method_name, fixture_name)
                  end
                end
              end

              def proxy_method_warning_if_called_in_before_context_scope(method_name, fixture_name)
                define_method(method_name) do |*args, **kwargs, &blk|
                  if RSpec.current_scope == :before_context_hook
                    RSpec.warn_with("Calling fixture method in before :context ")
                  else
                    access_fixture(fixture_name, *args, **kwargs, &blk)
                  end
                end
              end
            else
              def fixtures(*args)
                orig_methods = private_instance_methods
                super.tap do
                  new_methods = private_instance_methods - orig_methods
                  new_methods.each do |method_name|
                    proxy_method_warning_if_called_in_before_context_scope(method_name)
                  end
                end
              end

              def proxy_method_warning_if_called_in_before_context_scope(method_name)
                orig_implementation = instance_method(method_name)
                define_method(method_name) do |*args, &blk|
                  if RSpec.current_scope == :before_context_hook
                    RSpec.warn_with("Calling fixture method in before :context ")
                  else
                    orig_implementation.bind(self).call(*args, &blk)
                  end
                end
              end
            end
          end
          # rubocop:enable Metrics/BlockLength
        end
      end
    end
  end
end

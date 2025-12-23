# frozen_string_literal: true

# This is shamelessly borrowed from RuboCop RSpec
# https://github.com/rubocop-hq/rubocop-rspec/blob/master/lib/rubocop/rspec/inject.rb
module TestProf
  module Cops
    # Because RuboCop doesn't yet support plugins, we have to monkey patch in a
    # bit of our configuration.
    module Inject
      PROJECT_ROOT = Pathname.new(__dir__).parent.parent.parent.expand_path.freeze
      CONFIG_DEFAULT = PROJECT_ROOT.join("config", "default.yml").freeze

      def self.defaults!
        path = CONFIG_DEFAULT.to_s
        hash = RuboCop::ConfigLoader.send(:load_yaml_configuration, path)
        config = RuboCop::Config.new(hash, path)
        puts "configuration from #{path}" if RuboCop::ConfigLoader.debug?
        config = RuboCop::ConfigLoader.merge_with_default(config, path)
        RuboCop::ConfigLoader.instance_variable_set(:@default_configuration, config)
      end
    end
  end
end

TestProf::Cops::Inject.defaults!

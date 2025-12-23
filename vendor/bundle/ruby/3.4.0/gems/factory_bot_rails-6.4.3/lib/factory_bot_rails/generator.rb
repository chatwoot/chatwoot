require "factory_bot_rails/generators/rspec_generator"
require "factory_bot_rails/generators/non_rspec_generator"
require "factory_bot_rails/generators/null_generator"

module FactoryBotRails
  class Generator
    def initialize(config)
      @generators = config.app_generators
    end

    def run
      generator.new(@generators).run
    end

    def generator
      return Generators::NullGenerator if factory_bot_disabled?

      if test_framework == :rspec
        Generators::RSpecGenerator
      else
        Generators::NonRSpecGenerator
      end
    end

    def test_framework
      rails_options[:test_framework]
    end

    def factory_bot_disabled?
      rails_options[:factory_bot] == false
    end

    def rails_options
      @generators.options[:rails]
    end
  end
end

# frozen_string_literal: true

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.use_transactional_tests = true

  class << self
    def requires_active_record_version(version_string, &blk)
      return unless Gem::Dependency.new('', version_string).match?('', ActiveRecord::VERSION::STRING)
      instance_eval(&blk)
    end

    def assertion(name, &block)
      mc = class << self; self; end
      mc.class_eval do
        define_method(name) do
          it(name, &block)
        end
      end
    end

    def asssertion_group(name, &block)
      mc = class << self; self; end
      mc.class_eval do
        define_method(name, &block)
      end
    end

    def macro(name, &block)
      class_eval do
        define_method(name, &block)
      end
    end

    def describe(description, toplevel = nil, &blk)
      text = toplevel ? description : "#{name} #{description}"
      klass = Class.new(self)

      klass.class_eval <<-RUBY_EVAL
        def self.name
          "#{text}"
        end
      RUBY_EVAL

      # do not inherit test methods from the superclass
      klass.class_eval do
        instance_methods.grep(/^test.+/) do |method|
          undef_method method
        end
      end

      klass.instance_eval(&blk)
    end
    alias context describe

    def let(name, &blk)
      define_method(name) do
        instance_variable_name = "@__let_#{name}"
        return instance_variable_get(instance_variable_name) if instance_variable_defined?(instance_variable_name)
        instance_variable_set(instance_variable_name, instance_eval(&blk))
      end
    end

    def it(description, &blk)
      define_method("test_#{name}_#{description}", &blk)
    end
  end
end

def describe(description, &blk)
  ActiveSupport::TestCase.describe(description, true, &blk)
end

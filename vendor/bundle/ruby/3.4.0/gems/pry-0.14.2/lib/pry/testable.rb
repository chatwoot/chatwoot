# frozen_string_literal: true

# good idea ???
# if you're testing pry plugin you should require pry by yourself, no?
require 'pry' unless defined?(Pry)

class Pry
  module Testable
    require_relative "testable/pry_tester"
    require_relative "testable/evalable"
    require_relative "testable/mockable"
    require_relative "testable/variables"
    require_relative "testable/utility"

    #
    # When {Pry::Testable} is included into another module or class,
    # the following modules are also included: {Pry::Testable::Mockable},
    # {Pry::Testable::Evalable}, {Pry::Testable::Variables}, and
    # {Pry::Testable::Utility}.
    #
    # @note
    #   Each of the included modules mentioned above may also be used
    #   standalone or in a pick-and-mix fashion.
    #
    # @param [Module] mod
    #   A class or module.
    #
    # @return [void]
    #
    def self.included(mod)
      mod.module_eval do
        include Pry::Testable::Mockable
        include Pry::Testable::Evalable
        include Pry::Testable::Variables
        include Pry::Testable::Utility
      end
    end

    #
    # Sets various configuration options that make Pry optimal for a test
    # environment, see source code for complete details.
    #
    # @return [void]
    #
    def self.set_testenv_variables
      Pry.config = Pry::Config.new.merge(
        color: false,
        pager: false,
        should_load_rc: false,
        should_load_local_rc: false,
        correct_indent: false,
        collision_warning: false,
        history_save: false,
        history_load: false,
        hooks: Pry::Hooks.new
      )
    end

    #
    # Reset the Pry configuration to their default values.
    #
    # @return [void]
    #
    def self.unset_testenv_variables
      Pry.config = Pry::Config.new
    end
  end
end

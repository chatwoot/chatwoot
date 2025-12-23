# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/eval"

module Byebug
  #
  # Show methods of specific classes/modules/objects.
  #
  class MethodCommand < Command
    include Helpers::EvalHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* m(?:ethod)? \s+ (i(:?nstance)?\s+)?/x
    end

    def self.description
      <<-DESCRIPTION
        m[ethod] (i[nstance][ <obj>]|<class|module>)

        #{short_description}

        When invoked with "instance", shows instance methods of the object
        specified as argument or of self no object was specified.

        When invoked only with a class or module, shows class methods of the
        class or module specified as argument.
      DESCRIPTION
    end

    def self.short_description
      "Shows methods of an object, class or module"
    end

    def execute
      obj = warning_eval(@match.post_match)

      result =
        if @match[1]
          prc("method.methods", obj.methods.sort) { |item, _| { name: item } }
        elsif !obj.is_a?(Module)
          pr("variable.errors.not_module", object: @match.post_match)
        else
          prc("method.methods", obj.instance_methods(false).sort) do |item, _|
            { name: item }
          end
        end
      puts result
    end
  end
end

# frozen_string_literal: true

require_relative "../../helpers/eval"

module Byebug
  #
  # Reopens the +var+ command to define the +const+ subcommand
  #
  class VarCommand < Command
    #
    # Shows constants
    #
    class ConstCommand < Command
      include Helpers::EvalHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* c(?:onst)? (?:\s+ (.+))? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          v[ar] c[onstant]

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Shows constants of an object."
      end

      def execute
        obj = warning_eval(str_obj)
        return errmsg(pr("variable.errors.not_module", object: str_obj)) unless obj.is_a?(Module)

        constants = warning_eval("#{str_obj}.constants")
        puts prv(constants.sort.map { |c| [c, obj.const_get(c)] }, "constant")
      end

      private

      def str_obj
        @str_obj ||= @match[1] || "self.class"
      end
    end
  end
end

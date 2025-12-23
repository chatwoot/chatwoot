# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/eval"

module Byebug
  #
  # Enter Pry from byebug's prompt
  #
  class PryCommand < Command
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* pry \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        pry

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Starts a Pry session"
    end

    def execute
      return errmsg(pr("base.errors.only_local")) unless processor.interface.instance_of?(LocalInterface)

      begin
        require "pry"
      rescue LoadError
        return errmsg(pr("pry.errors.not_installed"))
      end

      Pry.start(context.frame._binding)
    end
  end
end

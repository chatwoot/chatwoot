require "minitest/autorun"
require "gli"
require "pp"

module TestHelper
  class CLIApp
    include GLI::App

    def reset
      super
      @subcommand_option_handling_strategy = :normal
    end
  end
end

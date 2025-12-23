require 'gli/command_finder.rb'
require 'gli/gli_option_block_parser.rb'
require 'gli/option_parser_factory.rb'
require 'gli/option_parsing_result.rb'
require 'gli/gli_option_parser.rb'
require 'gli/app_support.rb'
require 'gli/app.rb'
require 'gli/command_support.rb'
require 'gli/command.rb'
require 'gli/command_line_token.rb'
require 'gli/command_line_option.rb'
require 'gli/exceptions.rb'
require 'gli/flag.rb'
require 'gli/options.rb'
require 'gli/switch.rb'
require 'gli/argument.rb'
require 'gli/dsl.rb'
require 'gli/version.rb'
require 'gli/commands/help'
require 'gli/commands/compound_command'
require 'gli/commands/initconfig'
require 'gli/commands/rdoc_document_listener'
require 'gli/commands/doc'

module GLI
  include GLI::App

  def self.included(klass)
    warn "You should include GLI::App instead"
  end

  def self.run(*args)
    warn "GLI.run no longer works for GLI-2, you must just call `run(ARGV)' instead"
    warn "either fix your app, or use the latest GLI in the 1.x family"
    1
  end
end

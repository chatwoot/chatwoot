# frozen_string_literal: true

if RUBY_VERSION =~ /^1\.[89]\./
  require_relative 'parser/version'
  raise LoadError, <<-UNSUPPORTED_VERSION_MSG
parser v#{Parser::VERSION} cannot run on Ruby #{RUBY_VERSION}.
Please upgrade to Ruby 2.0.0 or higher, or use an older version of the parser gem.
  UNSUPPORTED_VERSION_MSG
end

require 'set'
require 'racc/parser'

require 'ast'

##
# @api public
#
module Parser
  require_relative 'parser/version'
  require_relative 'parser/messages'
  require_relative 'parser/deprecation'

  module AST
    require_relative 'parser/ast/node'
    require_relative 'parser/ast/processor'
    require_relative 'parser/meta'
  end

  module Source
    require_relative 'parser/source/buffer'
    require_relative 'parser/source/range'

    require_relative 'parser/source/comment'
    require_relative 'parser/source/comment/associator'

    require_relative 'parser/source/rewriter'
    require_relative 'parser/source/rewriter/action'
    require_relative 'parser/source/tree_rewriter'
    require_relative 'parser/source/tree_rewriter/action'

    require_relative 'parser/source/map'
    require_relative 'parser/source/map/operator'
    require_relative 'parser/source/map/collection'
    require_relative 'parser/source/map/constant'
    require_relative 'parser/source/map/variable'
    require_relative 'parser/source/map/keyword'
    require_relative 'parser/source/map/definition'
    require_relative 'parser/source/map/method_definition'
    require_relative 'parser/source/map/send'
    require_relative 'parser/source/map/index'
    require_relative 'parser/source/map/condition'
    require_relative 'parser/source/map/ternary'
    require_relative 'parser/source/map/for'
    require_relative 'parser/source/map/rescue_body'
    require_relative 'parser/source/map/heredoc'
    require_relative 'parser/source/map/objc_kwarg'
  end

  require_relative 'parser/syntax_error'
  require_relative 'parser/clobbering_error'
  require_relative 'parser/unknown_encoding_in_magic_comment_error'
  require_relative 'parser/diagnostic'
  require_relative 'parser/diagnostic/engine'

  require_relative 'parser/static_environment'

  if RUBY_ENGINE == 'truffleruby'
    require_relative 'parser/lexer-F0'
  else
    require_relative 'parser/lexer-F1'
  end
  require_relative 'parser/lexer-strings'
  require_relative 'parser/lexer/literal'
  require_relative 'parser/lexer/stack_state'
  require_relative 'parser/lexer/dedenter'

  module Builders
    require_relative 'parser/builders/default'
  end

  require_relative 'parser/context'
  require_relative 'parser/max_numparam_stack'
  require_relative 'parser/current_arg_stack'
  require_relative 'parser/variables_stack'

  require_relative 'parser/base'

  require_relative 'parser/rewriter'
  require_relative 'parser/tree_rewriter'
end

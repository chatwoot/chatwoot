require 'rubocop'

# Enforces use of from_email for email attribute lookups
class UseFromEmail < RuboCop::Cop::Base
  MSG = 'Use `from_email` for email lookups to ensure case insensitivity.'.freeze

  def_node_matcher :find_by_email?, <<~PATTERN
    (send _ :find_by (hash (pair (sym :email) _)))
  PATTERN

  def on_send(node)
    return unless find_by_email?(node)

    add_offense(node, message: MSG)
  end
end

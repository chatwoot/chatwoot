require 'rubocop'

module RuboCop::Cop::Chatwoot; end

# In the authorization code of a feature gated by `FeatureAccess` (the paths this cop is enabled
# for in .rubocop.yml), what an agent may use is the capability's answer, never the member's role.
# `administrator?` stays allowed: administrator-only operations are not capabilities, and
# administrators already pass every capability.
class RuboCop::Cop::Chatwoot::FeatureAccessRoleCheck < RuboCop::Cop::Base
  MSG = 'Decide what an agent may use with `FeatureAccess`, not with the member role.'.freeze

  def_node_matcher :role_check?, <<~PATTERN
    {
      (send _ :agent?)
      (csend _ :agent?)
      (send {(send _ :role) (csend _ :role)} {:== :!= :eql?} _)
    }
  PATTERN

  def on_send(node)
    return unless role_check?(node)

    add_offense(node, message: MSG)
  end
  alias on_csend on_send
end

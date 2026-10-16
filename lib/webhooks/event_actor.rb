# Only the actor identity is captured, before listeners run or an event is queued.
module Webhooks::EventActor
  TYPES = {
    'User' => 'user', 'AgentBot' => 'agent_bot', 'AutomationRule' => 'automation_rule', 'Contact' => 'contact', 'Inbox' => 'inbox'
  }.freeze

  def self.serialize(actor, account_id)
    type = TYPES[actor.class.name]
    return unless type && actor.persisted? && belongs_to_account?(actor, account_id)

    { type: type, id: actor.id }
  end

  def self.belongs_to_account?(actor, account_id)
    case actor
    when User
      actor.account_users.exists?(account_id: account_id)
    when AgentBot
      actor.account_id == account_id || (actor.account_id.nil? && actor.inboxes.exists?(account_id: account_id))
    else
      actor.account_id == account_id
    end
  end
  private_class_method :belongs_to_account?
end

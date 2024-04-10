class ResetAgentLastSeenAt < ActiveRecord::Migration[6.0]
  def change
    # rubocop:disable Rails/SkipsModelValidations
    ::Conversation.where('agent_last_seen_at > ?', DateTime.now.utc).update_all(agent_last_seen_at: DateTime.now.utc)
    # rubocop:enable Rails/SkipsModelValidations
  end
end

class AddAccountIdToAgentBotInboxes < ActiveRecord::Migration[6.0]
  def change
    add_column :agent_bot_inboxes, :account_id, :integer, index: true

    AgentBotInbox.all.each do |agent_bot_inbox|
      agent_bot_inbox.account_id = agent_bot_inbox.inbox.account_id
      agent_bot_inbox.save!
    end
  end
end

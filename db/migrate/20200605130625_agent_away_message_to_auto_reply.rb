class AgentAwayMessageToAutoReply < ActiveRecord::Migration[6.0]
  def change
    add_column :inboxes, :greeting_enabled, :boolean, default: false # rubocop:disable Rails/BulkChangeTable
    add_column :inboxes, :greeting_message, :string

    migrate_agent_away_to_greeting

    remove_column :channel_web_widgets, :agent_away_message, :string
  end

  def migrate_agent_away_to_greeting
    ::Channel::WebWidget.find_in_batches do |widget_batch|
      widget_batch.each do |widget|
        inbox = widget.inbox
        inbox.greeting_enabled = true
        inbox.greeting_message = widget.agent_away_message
        widget.save!
      end
    end
  end
end

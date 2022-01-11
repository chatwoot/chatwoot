class AddAllowMessagesAfterResolvedToInbox < ActiveRecord::Migration[6.1]
  def change
    add_column :inboxes, :allow_messages_after_resolved, :boolean, default: true

    update_csat_enabled_inboxes
  end

  def update_csat_enabled_inboxes
    ::Inbox.where(channel_type: 'Channel::WebWidget', csat_survey_enabled: true).find_in_batches do |inboxes_batch|
      inboxes_batch.each do |inbox|
        inbox.allow_messages_after_resolved = false
        inbox.save!
      end
    end
  end
end

class AddAudioNotificationEnableToInbox < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :audio_notification_enabled, :boolean, default: true
  end
end

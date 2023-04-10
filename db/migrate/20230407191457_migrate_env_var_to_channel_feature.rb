class MigrateEnvVarToChannelFeature < ActiveRecord::Migration[6.1]
  def change
    return unless ActiveModel::Type::Boolean.new.cast(ENV.fetch('USE_INBOX_AVATAR_FOR_BOT', false))

    Channel::WebWidget.find_in_batches do |widget_batch|
      widget_batch.each do |widget|
        widget.use_inbox_avatar_for_bot = true
        widget.save!
      end
    end
  end
end

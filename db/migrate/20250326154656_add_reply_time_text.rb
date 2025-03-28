class AddReplyTimeText < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_web_widgets, :reply_time_text, :string, default: 'We answer as fast as possible'
  end
end

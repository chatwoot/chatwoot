class AddReplyTimeToWebWidget < ActiveRecord::Migration[6.0]
  def change
    add_column :channel_web_widgets, :reply_time, :integer, default: 0
  end
end

class Remchannel < ActiveRecord::Migration[5.0]
  def change
    remove_column :conversations, :channel_id
    remove_column :messages, :channel_id
  end
end

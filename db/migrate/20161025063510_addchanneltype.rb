class Addchanneltype < ActiveRecord::Migration[5.0]
  def change
    add_column :inboxes, :channel_type, :string
  end
end

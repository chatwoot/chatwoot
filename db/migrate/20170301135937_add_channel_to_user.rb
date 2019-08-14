class AddChannelToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :channel, :string
  end
end

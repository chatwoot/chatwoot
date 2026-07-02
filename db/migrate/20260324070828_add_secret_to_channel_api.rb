class AddSecretToChannelApi < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_api, :secret, :string
  end
end

class RenameChannelEmailForwardAddress < ActiveRecord::Migration[6.0]
  def change
    rename_column :channel_email, :forward_to_address, :forward_to_email
  end
end

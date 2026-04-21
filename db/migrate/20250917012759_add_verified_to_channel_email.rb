class AddVerifiedToChannelEmail < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_email, :verified_for_sending, :boolean, default: false, null: false
  end
end

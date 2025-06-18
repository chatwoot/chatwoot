class AddSignatureIntoChannelEmails < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_email, :signature, :text, null: true, default: nil
  end
end

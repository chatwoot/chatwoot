class AddImapAuthenticationToChannelEmail < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_email, :imap_authentication, :string, default: 'plain'
  end
end

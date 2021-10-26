class AddImapConfigToChannelEmail < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_email, :imap_enabled, :boolean, default: false
    add_column :channel_email, :host, :string, default: ""
    add_column :channel_email, :port, :integer, default: 0
    add_column :channel_email, :user_email, :string, default: ""
    add_column :channel_email, :user_password, :string, default: ""
  end
end

class AddImapSmtpConfigToChannelEmail < ActiveRecord::Migration[6.1]
  def change
    # IMAP
    add_column :channel_email, :imap_enabled, :boolean, default: false
    add_column :channel_email, :imap_address, :string, default: ""
    add_column :channel_email, :imap_port, :integer, default: 0
    add_column :channel_email, :imap_email, :string, default: ""
    add_column :channel_email, :imap_password, :string, default: ""
    add_column :channel_email, :imap_enable_ssl, :boolean, default: true

    #SMTP
    add_column :channel_email, :smtp_enabled, :boolean, default: false
    add_column :channel_email, :smtp_address, :string, default: ""
    add_column :channel_email, :smtp_port, :integer, default: 0
    add_column :channel_email, :smtp_email, :string, default: ""
    add_column :channel_email, :smtp_password, :string, default: ""
    add_column :channel_email, :smtp_domain, :string, default: ""
    add_column :channel_email, :smtp_enable_starttls_auto, :boolean, default: true
    add_column :channel_email, :smtp_authentication, :string, default: "login"
  end
end

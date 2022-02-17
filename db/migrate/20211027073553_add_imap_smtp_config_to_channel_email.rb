class AddImapSmtpConfigToChannelEmail < ActiveRecord::Migration[6.1]
  def change
    change_table :channel_email, bulk: true do |t|
      # IMAP
      t.boolean :imap_enabled, default: false
      t.string :imap_address, default: ''
      t.integer :imap_port, default: 0
      t.string :imap_email, default: ''
      t.string :imap_password, default: ''
      t.boolean :imap_enable_ssl, default: true
      t.datetime :imap_inbox_synced_at

      # SMTP
      t.boolean :smtp_enabled, default: false
      t.string :smtp_address, default: ''
      t.integer :smtp_port, default: 0
      t.string :smtp_email, default: ''
      t.string :smtp_password, default: ''
      t.string :smtp_domain, default: ''
      t.boolean :smtp_enable_starttls_auto, default: true
      t.string :smtp_authentication, default: 'login'
    end
  end
end

class RenameImapEmailAndSmtpEmailColumns < ActiveRecord::Migration[6.1]
  def change
    rename_column :channel_email, :imap_email, :imap_login
    rename_column :channel_email, :smtp_email, :smtp_login
  end
end

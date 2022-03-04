class AddOpenSslVerifyModeToChannelEmail < ActiveRecord::Migration[6.1]
  def change
    change_table :channel_email, bulk: true do |t|
      t.string :smtp_openssl_verify_mode, default: 'none'
      t.boolean :smtp_enable_ssl_tls, default: false
    end
  end
end

class AddSecretToWebhooks < ActiveRecord::Migration[7.1]
  def up
    add_column :webhooks, :secret, :string
    Webhook.find_each do |webhook|
      webhook.update_column(:secret, SecureRandom.urlsafe_base64(24))
    end
  end

  def down
    remove_column :webhooks, :secret
  end
end

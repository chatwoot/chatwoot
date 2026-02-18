class AddSecretToWebhooks < ActiveRecord::Migration[7.1]
  def up
    add_column :webhooks, :secret, :string
    Webhook.find_each do |webhook|
      # rubocop:disable Rails/SkipsModelValidations
      webhook.update_column(:secret, SecureRandom.urlsafe_base64(24))
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down
    remove_column :webhooks, :secret
  end
end

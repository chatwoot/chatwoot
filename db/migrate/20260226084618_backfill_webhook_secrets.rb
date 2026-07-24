class BackfillWebhookSecrets < ActiveRecord::Migration[7.1]
  def up
    Webhook.find_each do |webhook|
      webhook.update!(secret: SecureRandom.urlsafe_base64(24))
    end
  end

  def down
    # no-op: removing the column in the previous migration handles cleanup
  end
end

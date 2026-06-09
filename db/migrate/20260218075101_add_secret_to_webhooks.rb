class AddSecretToWebhooks < ActiveRecord::Migration[7.1]
  def change
    add_column :webhooks, :secret, :string
  end
end

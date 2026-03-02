class AddOrderNotificationEmailToAccountCatalogSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :account_catalog_settings, :order_notification_email, :string
  end
end

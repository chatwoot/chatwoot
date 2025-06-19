class AddIndexForShopifyCustomer < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE INDEX index_contacts_custom_attrs_dot_shopify_customer_id
      ON contacts
      USING gin ((custom_attributes->'shopify_customer_id'));
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX IF EXISTS index_contacts_custom_attrs_dot_shopify_customer_id;
    SQL
  end
end

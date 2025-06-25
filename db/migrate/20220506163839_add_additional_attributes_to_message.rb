class AddAdditionalAttributesToMessage < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    add_column :messages, :additional_attributes, :jsonb, default: {}
    add_index :messages, "((additional_attributes->'campaign_id'))", name: 'index_messages_on_additional_attributes_campaign_id', using: 'gin',
                                                                     algorithm: :concurrently
  end

  def down
    remove_index :messages, name: 'index_messages_on_additional_attributes_campaign_id'
    remove_column :messages, :additional_attributes
  end
end

class AddExternalIdToFaqItems < ActiveRecord::Migration[7.0]
  def change
    add_column :faq_items, :external_id, :string
    add_index :faq_items, [:account_id, :external_id], unique: true, where: "external_id IS NOT NULL"
  end
end

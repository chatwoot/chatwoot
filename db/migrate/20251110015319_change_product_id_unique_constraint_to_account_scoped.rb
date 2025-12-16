class ChangeProductIdUniqueConstraintToAccountScoped < ActiveRecord::Migration[7.1]
  def change
    # Remove the old unique index on product_id
    remove_index :product_catalogs, name: 'index_product_catalogs_on_product_id'

    # Add new unique index on [account_id, product_id]
    # This ensures product_id is unique per account, not globally
    add_index :product_catalogs, [:account_id, :product_id], unique: true, name: 'index_product_catalogs_on_account_id_and_product_id'
  end
end

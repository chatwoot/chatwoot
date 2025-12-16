class AddUserTrackingToProductCatalogs < ActiveRecord::Migration[7.1]
  def change
    # user_id: tracks who created/inserted the product
    add_reference :product_catalogs, :user, foreign_key: true, null: true, index: true

    # last_updated_by_id: tracks who last updated the product
    add_column :product_catalogs, :last_updated_by_id, :bigint, null: true
    add_index :product_catalogs, :last_updated_by_id
    add_foreign_key :product_catalogs, :users, column: :last_updated_by_id

    # Backfill existing products with user_id from their bulk_processing_request
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE product_catalogs
          SET user_id = bulk_processing_requests.user_id,
              last_updated_by_id = bulk_processing_requests.user_id
          FROM bulk_processing_requests
          WHERE product_catalogs.bulk_processing_request_id = bulk_processing_requests.id
            AND product_catalogs.user_id IS NULL
        SQL
      end
    end
  end
end

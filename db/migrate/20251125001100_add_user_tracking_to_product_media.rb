class AddUserTrackingToProductMedia < ActiveRecord::Migration[7.1]
  def change
    # user_id: tracks who created/inserted the media
    add_reference :product_media, :user, foreign_key: true, null: true, index: true

    # last_updated_by_id: tracks who last updated the media
    add_column :product_media, :last_updated_by_id, :bigint, null: true
    add_index :product_media, :last_updated_by_id
    add_foreign_key :product_media, :users, column: :last_updated_by_id

    # Backfill existing media with user_id from their product's bulk_processing_request
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE product_media
          SET user_id = bulk_processing_requests.user_id,
              last_updated_by_id = bulk_processing_requests.user_id
          FROM product_catalogs
          JOIN bulk_processing_requests ON product_catalogs.bulk_processing_request_id = bulk_processing_requests.id
          WHERE product_media.product_catalog_id = product_catalogs.id
            AND product_media.user_id IS NULL
        SQL
      end
    end
  end
end

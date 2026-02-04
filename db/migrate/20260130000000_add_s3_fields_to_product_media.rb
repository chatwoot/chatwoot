class AddS3FieldsToProductMedia < ActiveRecord::Migration[7.1]
  def change
    add_column :product_media, :s3_key, :string
    add_column :product_media, :s3_status, :string, default: 'pending'
    add_column :product_media, :original_url, :string, comment: 'Original URL received from the upload file'
    add_column :product_media, :s3_error, :text
    add_column :product_media, :s3_uploaded_at, :datetime

    add_index :product_media, :s3_status
    add_index :product_media, :s3_key

    # Add comment to existing file_url column
    change_column_comment :product_media, :file_url, 'Static URL from external server. By default, uses the URL from the upload file'
  end
end

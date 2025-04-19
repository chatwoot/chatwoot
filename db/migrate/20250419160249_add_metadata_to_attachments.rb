class AddMetadataToAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :attachments, :metadata, :jsonb
  end
end

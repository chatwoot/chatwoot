class AddMetaToAttachment < ActiveRecord::Migration[7.0]
  def change
    add_column :attachments, :meta, :jsonb, default: {}
  end
end

class AddExternalCodeIntoAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :attachments, :external_code, :string, index: true, null: true, limit: 255
  end
end

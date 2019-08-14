class AddFallbackTitleToAttachments < ActiveRecord::Migration[5.0]
  def change
    add_column :attachments, :fallback_title, :string, default: nil
  end
end

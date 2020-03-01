class AddAdditionalAttributesToContact < ActiveRecord::Migration[6.0]
  def change
    add_column :contacts, :additional_attributes, :jsonb
  end
end

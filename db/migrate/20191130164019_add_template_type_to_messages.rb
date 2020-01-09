class AddTemplateTypeToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :content_type, :integer, default: '0'
    add_column :messages, :content_attributes, :json, default: {}
  end
end

# frozen_string_literal: true

class AddCategoryToCustomAttributeDefinitions < ActiveRecord::Migration[7.1]
  def change
    add_column :custom_attribute_definitions, :category, :string, null: false, default: ''
  end
end

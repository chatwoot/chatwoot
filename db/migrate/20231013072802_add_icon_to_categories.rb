class AddIconToCategories < ActiveRecord::Migration[7.0]
  def change
    add_column :categories, :icon, :string, default: ''
  end
end

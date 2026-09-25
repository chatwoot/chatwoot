class AddIconColorToCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :categories, :icon_color, :string, default: ''
  end
end

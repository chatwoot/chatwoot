class AddIndexOnCategorySlugAndLocale < ActiveRecord::Migration[6.1]
  def change
    add_column :categories, :slug, :string, null: false, default: 'Category'
    Category.connection.execute('update categories set slug = CONCAT(name, id)')
    add_index :categories, [:slug, :locale, :portal_id], unique: true
  end
end

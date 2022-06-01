class AddIndexOnCategorySlugAndLocale < ActiveRecord::Migration[6.1]
  def change
    add_column :categories, :slug, :string, null: false, default: 'common'
    add_index :categories, [:slug, :locale], unique: true
  end
end

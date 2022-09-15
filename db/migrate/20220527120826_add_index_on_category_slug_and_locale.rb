class AddIndexOnCategorySlugAndLocale < ActiveRecord::Migration[6.1]
  def change
    add_column :categories, :slug, :string, null: false, default: ''
    add_index :categories, [:slug, :locale, :portal_id], unique: true
    change_column_default :categories, :slug, from: '', to: nil
  end
end

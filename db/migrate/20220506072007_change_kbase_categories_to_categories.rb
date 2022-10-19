class ChangeKbaseCategoriesToCategories < ActiveRecord::Migration[6.1]
  def change
    rename_table :kbase_categories, :categories
  end
end

class RenameLinkedCategoryColumnName < ActiveRecord::Migration[6.1]
  def change
    rename_column :categories, :linked_category, :associated_category
  end
end

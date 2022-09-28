class RenameLinkedCategoryColumnName < ActiveRecord::Migration[6.1]
  def change
    rename_column :categories, :linked_category_id, :associated_category_id
  end
end

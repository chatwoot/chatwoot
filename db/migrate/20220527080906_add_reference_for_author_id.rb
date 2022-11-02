class AddReferenceForAuthorId < ActiveRecord::Migration[6.1]
  def change
    remove_column :articles, :author_id, :integer
    add_reference :articles, :author, foreign_key: { to_table: :users }
  end
end

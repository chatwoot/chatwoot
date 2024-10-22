class AddUniqueIndexToCustomApiName < ActiveRecord::Migration[7.0]
  def change
    add_index :custom_apis, :name, unique: true
  end
end

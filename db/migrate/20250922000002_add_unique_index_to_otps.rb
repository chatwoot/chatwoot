class AddUniqueIndexToOtps < ActiveRecord::Migration[7.0]
  def change
    # Remove existing index if it conflicts
    remove_index :otps, [:user_id, :purpose, :verified] if index_exists?(:otps, [:user_id, :purpose, :verified])
    
    # Add unique index for user_id and purpose combination
    add_index :otps, [:user_id, :purpose], unique: true, name: 'index_otps_on_user_id_and_purpose_unique'
  end
end
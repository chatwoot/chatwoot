class AddIndexToUsersPhoneNumber < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :phone_number, unique: true, where: "phone_number IS NOT NULL AND phone_number != ''"
  end
end

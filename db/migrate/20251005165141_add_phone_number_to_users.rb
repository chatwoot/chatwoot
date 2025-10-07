class AddPhoneNumberToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :phone_number, :string
  end
end

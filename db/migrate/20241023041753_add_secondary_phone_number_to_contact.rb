class AddSecondaryPhoneNumberToContact < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :secondary_phone_number, :text, null: true
  end
end

class ChangeDefaultContactTypeInContacts < ActiveRecord::Migration[7.0]
  def change
    change_column_default :contacts, :contact_type, from: 0, to: 1
  end
end

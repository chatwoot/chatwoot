class SetDefaultEmptyStringForContactName < ActiveRecord::Migration[7.0]
  def change
    change_column_default :contacts, :name, from: nil, to: ''
  end
end

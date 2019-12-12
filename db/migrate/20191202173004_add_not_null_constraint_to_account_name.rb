class AddNotNullConstraintToAccountName < ActiveRecord::Migration[6.0]
  def change
    change_column_null :accounts, :name, false
  end
end

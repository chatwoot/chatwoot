class ChangeContactToBigint < ActiveRecord::Migration[5.0]
  def change
    change_column :contacts, :id, :bigint
  end
end

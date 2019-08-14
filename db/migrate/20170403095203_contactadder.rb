class Contactadder < ActiveRecord::Migration[5.0]
  def change
    change_column :contacts, :id, :integer
    add_column :contacts, :source_id, :bigserial
  end
end

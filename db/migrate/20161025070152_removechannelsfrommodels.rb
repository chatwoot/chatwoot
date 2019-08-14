class Removechannelsfrommodels < ActiveRecord::Migration[5.0]
  def change
    remove_column :contacts, :channel_id
    add_column :contacts, :inbox_id, :integer
  end
end

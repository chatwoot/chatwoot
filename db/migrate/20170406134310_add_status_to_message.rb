class AddStatusToMessage < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :status, :integer, default: 0
  end
end

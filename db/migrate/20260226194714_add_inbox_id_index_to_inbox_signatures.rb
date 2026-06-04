class AddInboxIdIndexToInboxSignatures < ActiveRecord::Migration[7.1]
  def change
    add_index :inbox_signatures, :inbox_id
  end
end

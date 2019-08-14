class ChangeTypeToMessageType < ActiveRecord::Migration[5.0]
  def change
    rename_column :messages, :type, :message_type
  end
end

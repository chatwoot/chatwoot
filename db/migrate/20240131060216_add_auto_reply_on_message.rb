class AddAutoReplyOnMessage < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :auto_reply, :boolean, default: false
  end
end

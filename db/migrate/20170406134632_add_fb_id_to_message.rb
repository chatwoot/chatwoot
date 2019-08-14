class AddFbIdToMessage < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :fb_id, :string
  end
end

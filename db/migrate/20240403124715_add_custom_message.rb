class AddCustomMessage < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :customized, :boolean, default: false
  end
end

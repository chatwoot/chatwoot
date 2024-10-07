class AddActiveStatusOnSmartAction < ActiveRecord::Migration[7.0]
  def change
    add_column :smart_actions, :active, :boolean, default: true
  end
end

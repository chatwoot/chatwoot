class AddActiveStatusOnSmartAction < ActiveRecord::Migration[7.0]
  def change
    print ENV.to_json
    add_column :smart_actions, :active, :boolean, default: true
  end
end

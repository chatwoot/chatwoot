class AddTimeZoneToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :timezone, :string, default: 'UTC'
  end
end

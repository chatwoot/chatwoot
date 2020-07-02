class AddAvailabilityToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :availability, :integer, default: 0
  end
end

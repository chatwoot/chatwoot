class AddAutoResolveDurationToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :auto_resolve_duration, :integer
  end
end

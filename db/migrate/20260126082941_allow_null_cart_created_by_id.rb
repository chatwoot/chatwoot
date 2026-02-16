class AllowNullCartCreatedById < ActiveRecord::Migration[7.1]
  def change
    change_column_null :carts, :created_by_id, true
  end
end

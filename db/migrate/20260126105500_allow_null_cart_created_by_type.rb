class AllowNullCartCreatedByType < ActiveRecord::Migration[7.1]
  def change
    change_column_null :carts, :created_by_type, true
  end
end

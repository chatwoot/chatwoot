class EnsureMessagePrivateNotNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :messages, :private, false, false
  end
end

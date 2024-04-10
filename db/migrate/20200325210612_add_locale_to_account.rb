class AddLocaleToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :locale, :integer, default: 0
  end
end

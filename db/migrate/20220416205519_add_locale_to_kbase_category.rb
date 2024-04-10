class AddLocaleToKbaseCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :kbase_categories, :locale, :string, default: 'en'
    add_index :kbase_categories, :locale
    add_index :kbase_categories, [:locale, :account_id]
  end
end

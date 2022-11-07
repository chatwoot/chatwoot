class SetDefaultLocaleAtAccounts < ActiveRecord::Migration[6.1]
  def change
    change_column_default :accounts, :locale, from: nil, to: 0
  end
end

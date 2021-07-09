
class ChangeGupshupAccountIdType < ActiveRecord::Migration[6.0]
  def change
    change_column :channel_gupshup, :account_id, 'integer USING CAST(account_id AS integer)'
  end
end


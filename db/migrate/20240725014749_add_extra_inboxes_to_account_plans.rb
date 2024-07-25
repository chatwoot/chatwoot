class AddExtraInboxesToAccountPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :account_plans, :extra_inboxes, :integer, default: 0
  end
end

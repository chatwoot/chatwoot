class CreateAccountAddons < ActiveRecord::Migration[7.1]
  # An AccountAddon activates an Addon (from the catalog) for a specific account
  # for a given period. The period must fall within the account's current base
  # package period (validated on the model).
  #
  # `duration_type` records how the period was defined ("fixed_months",
  # "until_package_end" or "custom") so the edit form can re-select the mode and
  # re-resolve the period (e.g. an "until package end" add-on can be re-saved to
  # extend to a newly-extended package). `duration_months` stores the fixed
  # length when `duration_type` is "fixed_months".
  def change
    create_table :account_addons do |t|
      t.bigint :account_id, null: false
      t.bigint :addon_id, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :duration_type, null: false, default: 'custom'
      t.integer :duration_months

      t.timestamps
    end
    add_index :account_addons, :account_id
    add_index :account_addons, :addon_id
    add_index :account_addons, [:account_id, :ends_at]
  end
end

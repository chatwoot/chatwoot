class AddAccountFeatureFlag < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :feature_flags, :integer, index: true, default: 0, null: false
  end
end

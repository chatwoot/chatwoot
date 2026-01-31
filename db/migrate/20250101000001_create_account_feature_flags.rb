# frozen_string_literal: true

class CreateAccountFeatureFlags < ActiveRecord::Migration[7.0]
  def change
    create_table :account_feature_flags do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :flag_name, null: false, index: true
      t.boolean :enabled, null: false, default: false

      t.timestamps
    end

    # Ensure unique combination of account_id and flag_name
    add_index :account_feature_flags, [:account_id, :flag_name], unique: true
  end
end
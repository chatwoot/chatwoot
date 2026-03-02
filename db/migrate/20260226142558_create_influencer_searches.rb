class CreateInfluencerSearches < ActiveRecord::Migration[7.0]
  def change
    create_table :influencer_searches do |t|
      t.references :account, null: false, foreign_key: true
      t.jsonb :query_params, default: {}
      t.jsonb :results, default: []
      t.integer :results_count, default: 0
      t.float :credits_used
      t.timestamps
    end

    add_index :influencer_searches, [:account_id, :created_at]
  end
end

class AddScoringToAutonomiaProspecting < ActiveRecord::Migration[7.1]
  def change
    create_table :autonomia_prospecting_scoring_profiles do |t|
      t.string :name, null: false, default: 'Padrão'
      t.jsonb :weights, null: false, default: {}
      t.boolean :default, null: false, default: false
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end

    add_index :autonomia_prospecting_scoring_profiles,
              :default,
              unique: true,
              where: '"default" = TRUE',
              name: 'idx_autonomia_prospecting_scoring_profiles_default'

    change_table :autonomia_prospecting_leads, bulk: true do |t|
      t.decimal :score, precision: 5, scale: 2
      t.decimal :priority_score, precision: 5, scale: 2
      t.integer :priority_position
      t.integer :search_rank
      t.jsonb :score_breakdown, null: false, default: {}
      t.jsonb :negative_factors, null: false, default: []
      t.string :human_insight
    end

    change_table :autonomia_prospecting_settings, bulk: true do |t|
      t.string :scoring_mode, null: false, default: 'profile'
      t.references :scoring_profile,
                   foreign_key: { to_table: :autonomia_prospecting_scoring_profiles, on_delete: :nullify },
                   index: { name: 'idx_autonomia_prospecting_settings_scoring_profile' }
      t.jsonb :custom_scoring_weights, null: false, default: {}
    end

    add_index :autonomia_prospecting_leads, [:account_id, :priority_score],
              name: 'idx_autonomia_prospecting_leads_account_priority'
    add_index :autonomia_prospecting_leads, [:account_id, :score],
              name: 'idx_autonomia_prospecting_leads_account_score'
    add_index :autonomia_prospecting_leads, [:account_id, :search_rank],
              name: 'idx_autonomia_prospecting_leads_account_search_rank'
  end
end

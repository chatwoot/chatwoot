class AddAreaToAutonomiaProspectingSearches < ActiveRecord::Migration[7.0]
  def change
    change_table :autonomia_prospecting_searches, bulk: true do |t|
      t.string :area_type, null: false, default: 'radius'
      t.jsonb :area_config, null: false, default: {}
    end

    add_index :autonomia_prospecting_searches, [:account_id, :area_type],
              name: 'idx_autonomia_prospecting_searches_acc_area'
  end
end

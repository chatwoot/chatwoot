class CreateAutonomiaProspectingTables < ActiveRecord::Migration[7.0]
  def change
    create_table :autonomia_prospecting_settings do |t|
      t.references :account,
                   null: false,
                   foreign_key: { on_delete: :cascade },
                   index: { unique: true }
      t.boolean :provider_enabled, null: false, default: false
      t.string :provider, null: false, default: 'mock'
      t.integer :default_limit, null: false, default: 20
      t.integer :max_results_per_search, null: false, default: 20
      t.integer :daily_limit
      t.integer :monthly_limit
      t.integer :cache_ttl_seconds, null: false, default: 86_400
      t.boolean :enrichment_enabled, null: false, default: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :autonomia_prospecting_searches do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :user, foreign_key: { on_delete: :nullify }, index: true
      t.string :query, null: false
      t.string :location
      t.integer :radius
      t.string :provider, null: false, default: 'mock'
      t.integer :status, null: false, default: 0
      t.integer :requested_limit, null: false, default: 20
      t.integer :consumed_api_units, null: false, default: 0
      t.string :cache_key
      t.datetime :cache_expires_at
      t.jsonb :categories, null: false, default: []
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :autonomia_prospecting_searches, [:account_id, :created_at],
              name: 'idx_autonomia_prospecting_searches_acc_created'
    add_index :autonomia_prospecting_searches, [:account_id, :cache_key],
              name: 'idx_autonomia_prospecting_searches_acc_cache'

    create_table :autonomia_prospecting_leads do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :prospect_search,
                   foreign_key: { to_table: :autonomia_prospecting_searches, on_delete: :nullify },
                   index: { name: 'index_autonomia_prospecting_leads_on_search_id' }
      t.references :contact, foreign_key: { on_delete: :nullify }, index: true
      t.bigint :crm_card_id, index: true
      t.string :provider, null: false, default: 'mock'
      t.string :provider_place_id
      t.string :name, null: false
      t.string :phone
      t.string :website
      t.string :address
      t.string :city
      t.string :state
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.decimal :rating, precision: 3, scale: 2
      t.integer :reviews_count
      t.string :category
      t.string :dedupe_key, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :raw_payload, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_foreign_key :autonomia_prospecting_leads,
                    :crm_cards,
                    column: :crm_card_id,
                    on_delete: :nullify
    add_index :autonomia_prospecting_leads, [:account_id, :dedupe_key], unique: true
    add_index :autonomia_prospecting_leads, [:account_id, :provider, :provider_place_id],
              unique: true,
              name: 'idx_autonomia_prospecting_leads_provider_place',
              where: 'provider_place_id IS NOT NULL'
    add_index :autonomia_prospecting_leads, [:account_id, :status]

    create_table :autonomia_prospecting_lists do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :user, foreign_key: { on_delete: :nullify }, index: true
      t.string :name, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :autonomia_prospecting_lists, [:account_id, :name]

    create_table :autonomia_prospecting_list_leads do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :prospect_list,
                   null: false,
                   foreign_key: { to_table: :autonomia_prospecting_lists, on_delete: :cascade },
                   index: { name: 'idx_autonomia_prospecting_list_leads_list_id' }
      t.references :prospect_lead,
                   null: false,
                   foreign_key: { to_table: :autonomia_prospecting_leads, on_delete: :cascade },
                   index: { name: 'idx_autonomia_prospecting_list_leads_lead_id' }

      t.timestamps
    end

    add_index :autonomia_prospecting_list_leads, [:prospect_list_id, :prospect_lead_id],
              unique: true,
              name: 'idx_autonomia_prospecting_list_leads_unique'
  end
end

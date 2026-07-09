class AddEnrichmentFieldsToAutonomiaProspectingLeads < ActiveRecord::Migration[7.0]
  def change
    change_table :autonomia_prospecting_leads, bulk: true do |t|
      t.string :enrichment_status, null: false, default: 'pending'
      t.datetime :enrichment_requested_at
      t.datetime :enrichment_completed_at
      t.string :enrichment_source
      t.string :enrichment_error
      t.jsonb :enriched_data, null: false, default: {}
      t.string :decision_name
      t.string :decision_role
      t.decimal :decision_confidence, precision: 3, scale: 2
      t.string :decision_source_url
      t.string :decision_linkedin
      t.string :decision_instagram
      t.string :enriched_email
      t.string :enriched_whatsapp
      t.string :enriched_instagram
      t.string :enriched_linkedin
      t.string :enriched_facebook
      t.string :enriched_cnpj
      t.text :enrichment_summary
    end

    add_index :autonomia_prospecting_leads, %i[account_id enrichment_status],
              name: 'idx_autonomia_prospecting_leads_account_enrichment'
    add_index :autonomia_prospecting_leads, %i[account_id enrichment_completed_at],
              name: 'idx_autonomia_prospecting_leads_account_enriched_at'
  end
end

class AddGovernanceAndQualityToProspecting < ActiveRecord::Migration[7.0]
  def change
    change_table :autonomia_prospecting_settings, bulk: true do |t|
      t.references :default_crm_pipeline,
                   foreign_key: { to_table: :crm_pipelines, on_delete: :nullify },
                   index: { name: 'idx_autonomia_prospecting_settings_default_pipeline' }
      t.references :default_crm_stage,
                   foreign_key: { to_table: :crm_pipeline_stages, on_delete: :nullify },
                   index: { name: 'idx_autonomia_prospecting_settings_default_stage' }
    end

    change_table :autonomia_prospecting_leads, bulk: true do |t|
      t.string :discard_reason
    end
  end
end

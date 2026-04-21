class AddPipelineStageToSynapseosLeads < ActiveRecord::Migration[7.1]
  def change
    add_reference :synapseos_leads,
                  :pipeline_stage,
                  null: true,
                  foreign_key: { to_table: :synapseos_pipeline_stages }
    add_index :synapseos_leads, [:account_id, :pipeline_stage_id, :created_at],
              name: 'idx_synapseos_leads_stage_time'
  end
end

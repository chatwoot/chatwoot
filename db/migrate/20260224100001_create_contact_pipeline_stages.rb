class CreateContactPipelineStages < ActiveRecord::Migration[7.0]
  def change
    create_table :contact_pipeline_stages do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :pipeline_stage, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end

    add_index :contact_pipeline_stages, %i[contact_id pipeline_stage_id],
              unique: true, name: 'idx_contact_pipeline_stages_unique'
  end
end

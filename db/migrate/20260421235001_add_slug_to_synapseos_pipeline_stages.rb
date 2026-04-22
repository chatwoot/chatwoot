class AddSlugToSynapseosPipelineStages < ActiveRecord::Migration[7.1]
  def change
    add_column :synapseos_pipeline_stages, :slug, :string
    add_index :synapseos_pipeline_stages, [:account_id, :slug], unique: true
  end
end

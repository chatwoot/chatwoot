class AddDescriptionToSynapseosPipelineStages < ActiveRecord::Migration[7.1]
  def change
    add_column :synapseos_pipeline_stages, :description, :text
  end
end

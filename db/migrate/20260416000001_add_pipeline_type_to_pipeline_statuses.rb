# frozen_string_literal: true

class AddPipelineTypeToPipelineStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :pipeline_statuses, :pipeline_type, :string, null: false, default: 'conversation'
    add_index :pipeline_statuses, [:account_id, :pipeline_type]
  end
end

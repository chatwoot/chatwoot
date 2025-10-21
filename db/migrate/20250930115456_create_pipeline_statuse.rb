# frozen_string_literal: true

class CreatePipelineStatuse < ActiveRecord::Migration[7.1] # :nodoc:
  def change
    create_table :pipeline_statuses do |t|
      t.string :name, null: false
      t.references :account, index: true, null: false

      t.timestamps
    end
  end
end

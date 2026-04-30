# frozen_string_literal: true

class AddPipelineStatusToContacts < ActiveRecord::Migration[7.1]
  def change
    add_reference :contacts, :pipeline_status, foreign_key: { to_table: :pipeline_statuses }, null: true
  end
end

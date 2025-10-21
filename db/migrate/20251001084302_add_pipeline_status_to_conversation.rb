# frozen_string_literal: true

class AddPipelineStatusToConversation < ActiveRecord::Migration[7.1] # :nodoc:
  def change
    add_reference :conversations, :pipeline_status, index: true, foreign_key: true
  end
end

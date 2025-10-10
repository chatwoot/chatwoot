# frozen_string_literal: true

class AddMetadataToMessageTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :message_templates, :metadata, :jsonb, default: {}
    add_index :message_templates, :metadata, using: :gin
  end
end

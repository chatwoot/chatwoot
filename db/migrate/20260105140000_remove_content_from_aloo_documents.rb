# frozen_string_literal: true

class RemoveContentFromAlooDocuments < ActiveRecord::Migration[7.0]
  def change
    remove_column :aloo_documents, :content, :text
  end
end

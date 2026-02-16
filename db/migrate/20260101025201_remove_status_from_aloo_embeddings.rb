# frozen_string_literal: true

class RemoveStatusFromAlooEmbeddings < ActiveRecord::Migration[7.0]
  def change
    remove_column :aloo_embeddings, :status, :integer, default: 0
  end
end

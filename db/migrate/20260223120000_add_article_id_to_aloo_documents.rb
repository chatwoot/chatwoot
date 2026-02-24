# frozen_string_literal: true

class AddArticleIdToAlooDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :aloo_documents, :article_id, :bigint, null: true

    add_index :aloo_documents, :article_id
    add_index :aloo_documents, [:aloo_assistant_id, :article_id],
              unique: true,
              where: 'article_id IS NOT NULL',
              name: 'index_aloo_documents_on_assistant_and_article'
  end
end

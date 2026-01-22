# frozen_string_literal: true

class AddTextSourceAndRefreshToAlooDocuments < ActiveRecord::Migration[7.0]
  def change
    # text_content: for storing manual text content when source_type is 'text'
    add_column :aloo_documents, :text_content, :text

    # selected_pages: array of URLs selected by user for website scraping
    add_column :aloo_documents, :selected_pages, :jsonb, default: []

    # auto_refresh: whether to automatically re-scrape websites weekly
    add_column :aloo_documents, :auto_refresh, :boolean, default: false, null: false

    # last_refreshed_at: timestamp of last successful refresh
    add_column :aloo_documents, :last_refreshed_at, :datetime

    # next_refresh_at: when the next refresh should occur (indexed for efficient queries)
    add_column :aloo_documents, :next_refresh_at, :datetime

    # Index for efficient queries in the refresh job
    add_index :aloo_documents, :next_refresh_at, where: 'auto_refresh = true'
    add_index :aloo_documents, :auto_refresh
  end
end

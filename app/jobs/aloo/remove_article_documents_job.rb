# frozen_string_literal: true

class Aloo::RemoveArticleDocumentsJob < ApplicationJob
  queue_as :low

  def perform(article_id)
    Aloo::Document.where(article_id: article_id, source_type: 'article').find_each(&:destroy)
  end
end

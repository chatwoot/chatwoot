# frozen_string_literal: true

class Api::V1::Accounts::Aloo::EmbeddingsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_assistant

  def index
    @embeddings = @assistant.embeddings
                            .includes(:document)
                            .order(created_at: :desc)

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 50).to_i.clamp(1, 100)

    total_count = @embeddings.count
    @embeddings = @embeddings.offset((page - 1) * per_page).limit(per_page)

    render json: {
      payload: @embeddings.map { |e| embedding_json(e) },
      meta: {
        total_count: total_count,
        page: page,
        per_page: per_page,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  private

  def set_assistant
    @assistant = Current.account.aloo_assistants.find(params[:assistant_id])
  end

  def embedding_json(embedding)
    {
      id: embedding.id,
      content: embedding.content.truncate(500),
      question: embedding.question,
      document_id: embedding.aloo_document_id,
      document_title: embedding.document&.title,
      chunk_index: embedding.metadata&.dig('chunk_index'),
      token_count: embedding.metadata&.dig('token_count'),
      created_at: embedding.created_at
    }
  end

  def check_authorization
    authorize(Current.account, :update?)
  end
end

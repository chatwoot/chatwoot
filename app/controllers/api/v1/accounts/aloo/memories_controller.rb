# frozen_string_literal: true

class Api::V1::Accounts::Aloo::MemoriesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_assistant
  before_action :set_memory, only: [:destroy]

  def index
    @memories = @assistant.memories
                          .order(created_at: :desc)

    @memories = @memories.by_type(params[:memory_type]) if params[:memory_type].present?
    @memories = @memories.active if params[:active_only] == 'true'

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i.clamp(1, 100)

    total_count = @memories.count
    @memories = @memories.offset((page - 1) * per_page).limit(per_page)

    render json: {
      payload: @memories.map { |m| memory_json(m) },
      meta: {
        total_count: total_count,
        page: page,
        per_page: per_page,
        total_pages: (total_count.to_f / per_page).ceil,
        counts_by_type: memory_counts_by_type
      }
    }
  end

  def destroy
    @memory.destroy!
    head :ok
  end

  private

  def set_assistant
    @assistant = Current.account.aloo_assistants.find(params[:assistant_id])
  end

  def set_memory
    @memory = @assistant.memories.find(params[:id])
  end

  def memory_json(memory)
    {
      id: memory.id,
      memory_type: memory.memory_type,
      content: memory.content,
      source_excerpt: memory.source_excerpt,
      confidence: memory.confidence,
      observation_count: memory.observation_count,
      helpful_count: memory.helpful_count,
      not_helpful_count: memory.not_helpful_count,
      flagged_for_review: memory.flagged_for_review,
      contact_id: memory.contact_id,
      conversation_id: memory.conversation_id,
      entities: memory.entities,
      topics: memory.topics,
      last_observed_at: memory.last_observed_at,
      created_at: memory.created_at,
      updated_at: memory.updated_at
    }
  end

  def memory_counts_by_type
    @assistant.memories.group(:memory_type).count
  end

  def check_authorization
    authorize(Current.account, :update?)
  end
end

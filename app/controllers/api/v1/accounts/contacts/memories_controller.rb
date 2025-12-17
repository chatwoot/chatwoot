# frozen_string_literal: true

class Api::V1::Accounts::Contacts::MemoriesController < Api::V1::Accounts::Contacts::BaseController
  # GET /api/v1/accounts/:account_id/contacts/:contact_id/memories
  # Retrieve all memories for a contact with optional semantic search
  def index
    service = Zerodb::AgentMemoryService.new(Current.account.id)
    @memories = service.recall_memories(
      @contact.id,
      query: params[:query],
      limit: params[:limit]&.to_i || 10
    )

    render json: @memories
  end

  # POST /api/v1/accounts/:account_id/contacts/:contact_id/memories
  # Store a new memory for a contact
  def create
    service = Zerodb::AgentMemoryService.new(Current.account.id)

    @memory = service.store_memory(
      @contact.id,
      memory_params[:content],
      importance: memory_params[:importance] || 'medium',
      tags: memory_params[:tags] || []
    )

    render json: @memory, status: :created
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue Zerodb::BaseService::ZeroDBError => e
    render json: { error: "Failed to store memory: #{e.message}" }, status: :bad_gateway
  end

  private

  def memory_params
    params.permit(:content, :importance, tags: [])
  end
end

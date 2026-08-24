# frozen_string_literal: true

# [whisker] Knowledge Base API — CRUD for RAG knowledge entries
class Api::V1::Accounts::KnowledgeBasesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_entry, only: [:update, :destroy]

  def index
    @entries = current_account.knowledge_bases.order(updated_at: :desc)
  end

  def create
    @entry = current_account.knowledge_bases.build(entry_params)
    if @entry.save
      render json: @entry, status: :ok
    else
      render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @entry.update(entry_params)
      render json: @entry, status: :ok
    else
      render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy
    head :ok
  end

  def search
    results = RagRetrievalService.new(
      query: params[:q],
      account: current_account,
      limit: (params[:limit] || 5).to_i
    ).retrieve
    render json: results.map { |r| { id: r.id, name: r.name, content: r.content, category: r.category } }
  end

  private

  def fetch_entry
    @entry = current_account.knowledge_bases.find(params[:id])
  end

  def entry_params
    params.require(:knowledge_base).permit(:name, :content, :category, :enabled)
  end
end

# frozen_string_literal: true

class Api::V1::Accounts::Aloo::ConversationsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_assistant

  def index
    @contexts = @assistant.conversation_contexts
                          .includes(conversation: :contact)
                          .order(updated_at: :desc)

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i.clamp(1, 100)

    total_count = @contexts.count
    @contexts = @contexts.offset((page - 1) * per_page).limit(per_page)

    render json: {
      payload: @contexts.map { |c| conversation_context_json(c) },
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

  def conversation_context_json(context)
    conversation = context.conversation
    contact = conversation&.contact

    {
      id: context.id,
      conversation_id: context.conversation_id,
      contact_name: contact&.name || 'Unknown',
      contact_email: contact&.email,
      message_count: context.message_count,
      input_tokens: context.input_tokens,
      output_tokens: context.output_tokens,
      total_tokens: context.total_tokens,
      total_cost: context.total_cost,
      created_at: context.created_at,
      updated_at: context.updated_at
    }
  end

  def check_authorization
    authorize(Current.account, :update?)
  end
end

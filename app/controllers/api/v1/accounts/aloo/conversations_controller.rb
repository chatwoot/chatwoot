# frozen_string_literal: true

class Api::V1::Accounts::Aloo::ConversationsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_assistant

  def index
    @conversations = fetch_ai_conversations
    total_count = @conversations.count
    @conversations = paginate(@conversations)

    render json: {
      payload: @conversations.map { |c| conversation_json(c) },
      meta: pagination_meta(total_count)
    }
  end

  private

  def set_assistant
    @assistant = Current.account.aloo_assistants.find(params[:assistant_id])
  end

  def fetch_ai_conversations
    conversation_ids = Message
                       .joins(:conversation)
                       .where(conversations: { account_id: Current.account.id })
                       .where("content_attributes->>'aloo_generated' = ?", 'true')
                       .where("content_attributes->>'aloo_assistant_id' = ?", @assistant.id.to_s)
                       .reorder(nil)
                       .distinct
                       .pluck(:conversation_id)

    Conversation.where(id: conversation_ids).includes(:contact).order(updated_at: :desc)
  end

  def paginate(scope)
    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def page
    @page ||= (params[:page] || 1).to_i
  end

  def per_page
    @per_page ||= (params[:per_page] || 25).to_i.clamp(1, 100)
  end

  def pagination_meta(total_count)
    {
      total_count: total_count,
      page: page,
      per_page: per_page,
      total_pages: (total_count.to_f / per_page).ceil
    }
  end

  def conversation_json(conversation)
    ai_messages = assistant_messages(conversation)
    token_usage = calculate_token_usage(ai_messages)

    {
      id: conversation.id,
      conversation_id: conversation.id,
      contact_name: conversation.contact&.name || 'Unknown',
      contact_email: conversation.contact&.email,
      message_count: ai_messages.count,
      **token_usage,
      created_at: conversation.created_at,
      updated_at: conversation.updated_at
    }
  end

  def assistant_messages(conversation)
    conversation.messages.where("content_attributes->>'aloo_assistant_id' = ?", @assistant.id.to_s)
  end

  def calculate_token_usage(messages)
    input_tokens = messages.sum { |m| m.content_attributes['input_tokens'].to_i }
    output_tokens = messages.sum { |m| m.content_attributes['output_tokens'].to_i }

    {
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      total_tokens: input_tokens + output_tokens,
      total_cost: 0
    }
  end

  def check_authorization
    authorize(Current.account, :update?)
  end
end

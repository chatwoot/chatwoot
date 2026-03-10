# frozen_string_literal: true

class Api::V1::Accounts::Aloo::TasksController < Api::V1::Accounts::BaseController
  MAX_MESSAGES = 50

  def summarize
    conversation = find_conversation
    last_message = conversation.messages.order(created_at: :desc).pick(:id)
    cache_key = "conversation_summary/#{conversation.id}/#{last_message}"

    summary = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      messages = extract_messages(conversation)
      result = ConversationSummaryAgent.call(
        conversation_messages: messages,
        account_id: Current.account.id,
        conversation_id: conversation.display_id
      )
      result.content.is_a?(Hash) ? result.content[:summary] : result.content.to_s
    end

    render json: {
      message: summary,
      follow_up_context: {
        task: 'summarize',
        conversation_display_id: conversation.display_id
      }
    }
  end

  def reply_suggestion
    conversation = find_conversation
    messages = extract_messages(conversation)

    result = ReplySuggestionAgent.call(
      conversation_messages: messages,
      account_id: Current.account.id,
      conversation_id: conversation.display_id
    )

    render_task_result(result, :reply, conversation)
  end

  private

  def find_conversation
    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_display_id])
    authorize conversation, :show?
    conversation
  end

  def render_task_result(result, field, conversation)
    content = result.content.is_a?(Hash) ? result.content[field] : result.content.to_s

    render json: {
      message: content,
      follow_up_context: {
        task: action_name,
        conversation_display_id: conversation.display_id
      }
    }
  end

  def extract_messages(conversation)
    conversation.messages
                .where.not(content: [nil, ''])
                .order(created_at: :desc)
                .limit(MAX_MESSAGES)
                .reverse
                .map do |msg|
                  {
                    incoming: msg.incoming?,
                    content: msg.content
                  }
                end
  end
end

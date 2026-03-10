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
      follow_up_context: build_follow_up_context(conversation, summary)
    }
  end

  def rewrite
    conversation = find_conversation
    messages = extract_messages(conversation)

    result = ContentRewriteAgent.call(
      content: params[:content],
      operation: params[:operation],
      conversation_messages: messages,
      account_id: Current.account.id,
      conversation_id: conversation.display_id
    )

    render_task_result(result, :rewritten_content, conversation)
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

  def follow_up
    context = params[:follow_up_context]
    conversation = Current.account.conversations.find_by!(display_id: context[:conversation_display_id])
    authorize conversation, :show?

    messages = extract_messages(conversation)

    result = FollowUpAgent.call(
      previous_output: context[:previous_output],
      follow_up_message: params[:message],
      original_task: context[:task],
      conversation_messages: messages,
      account_id: Current.account.id,
      conversation_id: conversation.display_id
    )

    content = result.content.is_a?(Hash) ? result.content[:refined_content] : result.content.to_s

    render json: {
      message: content,
      follow_up_context: build_follow_up_context(conversation, content, context[:task])
    }
  end

  private

  def find_conversation
    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_display_id])
    authorize conversation, :show?
    conversation
  end

  def build_follow_up_context(conversation, content, task = action_name)
    {
      task: task,
      conversation_display_id: conversation.display_id,
      previous_output: content
    }
  end

  def render_task_result(result, field, conversation)
    content = result.content.is_a?(Hash) ? result.content[field] : result.content.to_s

    render json: {
      message: content,
      follow_up_context: build_follow_up_context(conversation, content)
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

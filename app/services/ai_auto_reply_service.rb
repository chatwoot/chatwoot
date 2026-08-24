# frozen_string_literal: true

# [whisker] AI Auto-Reply Service
# When an inbox has ai_auto_reply enabled, this service generates an AI response
# using the BYOR provider chain when no human agent is available.
#
# Triggered by IncomingMessageJobs after a new message is created.
class AiAutoReplyService
  pattr_initialize [:account!, :conversation!, :message!]

  def perform
    return unless should_auto_reply?

    response = generate_ai_response
    return if response.blank?

    create_reply(response)
    conversation.update!(status: :open) if conversation.pending?
  end

  private

  def should_auto_reply?
    inbox.ai_auto_reply? &&
      conversation.pending? &&
      !message.private? &&
      message.incoming? &&
      no_agents_online?
  end

  def no_agents_online?
    # Check if any human agents are available for this inbox
    available = Assignments::AssignAgentService.new(
      conversation: conversation,
      inverted: true
    ).available_agents
    available.empty?
  rescue StandardError
    true
  end

  def generate_ai_response
    task = AiReplyTask.new(account: account, conversation: conversation)
    result = task.perform
    return nil if result[:error]

    result[:message]
  end

  def create_reply(content)
    Messenger::MessageBuilder.new(
      conversation: conversation,
      message_type: :outgoing,
      content: content,
      private: false,
      sender: ai_sender
    ).perform
  end

  def ai_sender
    # Use the account's first bot or create a virtual AI sender
    account.agent_bots.first
  end

  def inbox
    conversation.inbox
  end

  # Inline task that wraps Captain::BaseTaskService for AI reply generation
  class AiReplyTask < Captain::BaseTaskService
    def event_name
      'ai_auto_reply'
    end

    private

    def captain_tasks_enabled?
      true
    end

    def counts_toward_usage?
      false
    end
  end
end

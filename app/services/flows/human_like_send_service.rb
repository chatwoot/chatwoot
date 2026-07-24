class Flows::HumanLikeSendService
  MAX_DELAY = 25

  def initialize(conversation:, flow_run:)
    @conversation = conversation
    @flow_run = flow_run
  end

  # delay_seconds: typing wait before the bubble is created
  def perform(content:, node_id:, buttons: nil, delay_seconds: 2)
    delay = delay_seconds.to_i.clamp(0, MAX_DELAY)
    trigger_typing!

    payload = {
      conversation_id: @conversation.id,
      flow_run_id: @flow_run.id,
      node_id: node_id,
      content: content,
      buttons: Array(buttons)
    }

    if delay.positive?
      Flows::DeferredSendJob.set(wait: delay.seconds).perform_later(payload)
    else
      Flows::DeferredSendJob.perform_later(payload)
    end
  end

  private

  def trigger_typing!
    Whatsapp::MarkReadTypingService.new(conversation: @conversation, force: true).perform
    user = typing_user
    return if user.blank?

    Conversations::TypingStatusManager.new(
      @conversation,
      user,
      { typing_status: 'on', is_private: false }
    ).toggle_typing_status
  rescue StandardError => e
    Rails.logger.warn("[Flows] typing failed conversation=#{@conversation.id}: #{e.class}: #{e.message}")
  end

  def typing_user
    @conversation.assignee ||
      @conversation.account.administrators.order(:id).first ||
      @conversation.account.users.order(:id).first
  end
end

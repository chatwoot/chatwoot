class Flows::DeferredSendJob < ApplicationJob
  queue_as :high

  def perform(payload)
    payload = payload.with_indifferent_access
    conversation = Conversation.find_by(id: payload[:conversation_id])
    run = FlowRun.find_by(id: payload[:flow_run_id])
    return if conversation.blank? || run.blank? || !run.active?

    create_message(conversation, run, payload)
    Flows::ExecutionService.new(run: run).advance_after_send!(payload[:node_id])
  end

  private

  def create_message(conversation, run, payload)
    content = payload[:content].to_s
    buttons = Array(payload[:buttons]).map do |btn|
      btn = btn.with_indifferent_access
      { 'title' => btn[:title].to_s.truncate(20), 'value' => btn[:value].presence || btn[:title].to_s }
    end

    params = {
      content: content,
      private: false,
      content_attributes: {
        flow_run_id: run.id,
        flow_node_id: payload[:node_id]
      }
    }

    if buttons.any?
      params[:content_type] = 'input_select'
      params[:content_attributes][:items] = buttons.first(3)
    end

    Messages::MessageBuilder.new(nil, conversation, params).perform
  end
end

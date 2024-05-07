class SmartActionBuilder
  attr_accessor :errors

  def initialize(conversation, params)
    @conversation = conversation
    @params = params
    @errors = []
  end

  def perform
    validate_params
    return if @errors.present?

    build_smart_action
  rescue StandardError => e
    @errors << e.message
    nil
  end

  private

  def validate_params
    return if @params.present?

    @errors << 'Missing parameters'
  end

  def build_smart_action
    @smart_action = @conversation.smart_actions.create(smart_action_params)
  end

  def smart_action_params
    @params.permit(
      :name,
      :label,
      :description,
      :event,
      :intent_type,
      :message_id,
      :to,
      :from,
      :link
    )
  end
end

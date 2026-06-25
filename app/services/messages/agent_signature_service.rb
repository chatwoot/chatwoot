class Messages::AgentSignatureService
  def initialize(message)
    @message = message
  end

  def perform
    return @message unless should_apply?

    original_content = @message.content.to_s.strip
    agent_name = formatted_agent_name
    signature = "#{agent_name}:"

    return @message if original_content.start_with?(signature)

    @message.content = "#{signature}\n#{original_content}"

    @message.content_attributes ||= {}
    @message.content_attributes['agent_signature_applied'] = true
    @message.content_attributes['agent_signature_original_content'] = original_content
    @message.content_attributes['agent_signature_agent_name'] = agent_name
    @message.content_attributes['agent_signature_agent_email'] = @message.sender&.email.to_s

    @message
  end

  private

  def should_apply?
    return false if @message.blank?
    return false unless @message.outgoing?
    return false if @message.private?
    return false unless @message.sender_type == 'User'
    return false if @message.content.blank?
    return false unless whatsapp_channel?
    return false if skip_agent_title?
    return false if already_signed?
    return false if template_message?
    return false if automation_message?

    true
  end

  def whatsapp_channel?
    @message.conversation&.inbox&.channel_type == 'Channel::Whatsapp'
  end

  def skip_agent_title?
    attrs = @message.conversation&.contact&.custom_attributes || {}
    value = attrs['skipagenttitle']

    value == true || value.to_s == 'true'
  end

  def already_signed?
    @message.content_attributes ||= {}
    @message.content_attributes['agent_signature_applied'] == true
  end

  def template_message?
    attrs = @message.additional_attributes || {}
    attrs['template_params'].present? || attrs[:template_params].present?
  end

  def automation_message?
    @message.content_attributes&.dig('automation_rule_id').present?
  end

  def formatted_agent_name
    display_name = @message.sender&.try(:available_name).to_s.strip
    name = display_name.presence || @message.sender&.name.to_s.strip

    return 'Atendente' if name.blank?

    name
  end
end

module Integrations::Slack::SlackLinkHelper
  def unfurl_url
    conversation = conversation_from_params
    return unless conversation

    user_info = conntact_attributes(conversation).slice(:user_name, :email, :phone_number, :company_name)
    unfurls = generate_unfurls(conversation_url, user_info)

    send_unfurls(unfurls)
  end

  def conntact_attributes(conversation)
    contact = conversation.contact
    user_name = contact&.name.presence || '---'
    email = contact&.email.presence || '---'
    phone_number = contact&.phone_number.presence || '---'
    company_name = contact&.additional_attributes&.dig('company_name').presence || '---'

    {
      user_name: user_name,
      email: email,
      phone_number: phone_number,
      company_name: company_name
    }
  end

  def conversation_from_params
    conversation_id = extract_conversation_id(conversation_url)
    return unless conversation_id

    find_conversation_by_id(conversation_id)
  end

  def conversation_url
    params.dig(:event, :links, 0, :url)
  end

  def send_unfurls(unfurls)
    slack_service = Integrations::Slack::SendOnSlackService.new(message: nil, hook: integration_hook)
    slack_service.link_unfurl(
      unfurl_id: params.dig(:event, :unfurl_id),
      source: params.dig(:event, :source),
      unfurls: JSON.generate(unfurls)
    )
  end
end

module Integrations::Slack::SlackLinkHelper
  def unfurl_url
    event_links = params.dig(:event, :links)
    return unless event_links

    event_links.each do |link_info|
      unfurl_link(link_info)
    end
  end

  def unfurl_link(link_info)
    url = link_info[:url]
    return unless url

    conversation = conversation_from_url(url)
    return unless conversation

    user_info = contact_attributes(conversation).slice(:user_name, :email, :phone_number, :company_name)
    unfurls = generate_unfurls(url, user_info)
    send_unfurls(unfurls, link_info)
  end

  def contact_attributes(conversation)
    contact = conversation.contact
    user_name = contact.name.presence || '---'
    email = contact.email.presence || '---'
    phone_number = contact.phone_number.presence || '---'
    company_name = contact.additional_attributes&.dig('company_name').presence || '---'

    {
      user_name: user_name,
      email: email,
      phone_number: phone_number,
      company_name: company_name
    }
  end

  def conversation_from_url(url)
    conversation_id = extract_conversation_id(url)
    return unless conversation_id

    find_conversation_by_id(conversation_id)
  end

  def send_unfurls(unfurls, _link_info)
    slack_service = Integrations::Slack::SendOnSlackService.new(message: nil, hook: integration_hook)
    slack_service.link_unfurl(
      unfurl_id: params.dig(:event, :unfurl_id),
      source: params.dig(:event, :source),
      unfurls: JSON.generate(unfurls)
    )
  end
end

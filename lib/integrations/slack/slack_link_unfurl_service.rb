class Integrations::Slack::SlackLinkUnfurlService
  pattr_initialize [:params!, :integration_hook!]

  def perform
    event_links = params.dig(:event, :links)
    return unless event_links

    event_links.each do |link_info|
      unfurl_link(link_info)
    end
  end

  def unfurl_link(link_info)
    url = link_info[:url]
    return unless url

    return unless valid_account?(url)

    conversation = conversation_from_url(url)
    return unless conversation

    user_info = contact_attributes(conversation).slice(:user_name, :email, :phone_number, :company_name)
    unfurls = Integrations::Slack::LinkUnfurlFormatter.new(url: url, user_info: user_info, inbox_name: conversation.inbox.name,
                                                           inbox_type: conversation.inbox.channel.name).perform
    send_unfurls(unfurls)
  end

  private

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

  def account_id_from_url(url)
    account_id_regex = %r{/accounts/(\d+)}
    match_data = url.match(account_id_regex)
    match_data[1] if match_data
  end

  def conversation_from_url(url)
    conversation_id = extract_conversation_id(url)
    return unless conversation_id

    find_conversation_by_id(conversation_id)
  end

  def send_unfurls(unfurls)
    slack_service = Integrations::Slack::SendOnSlackService.new(message: nil, hook: integration_hook)
    slack_service.link_unfurl(
      unfurl_id: params.dig(:event, :unfurl_id),
      source: params.dig(:event, :source),
      unfurls: JSON.generate(unfurls)
    )
  end

  def valid_account?(url)
    account_id = account_id_from_url(url)
    account_id == integration_hook.account_id.to_s
  end

  def extract_conversation_id(url)
    conversation_id_regex = %r{/conversations/(\d+)}
    match_data = url.match(conversation_id_regex)
    match_data[1] if match_data
  end

  def find_conversation_by_id(conversation_id)
    Conversation.find_by(display_id: conversation_id)
  end
end

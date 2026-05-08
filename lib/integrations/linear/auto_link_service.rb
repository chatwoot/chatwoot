class Integrations::Linear::AutoLinkService
  pattr_initialize [:hook!, :message!]

  LINEAR_URL_REGEX = %r{https?://linear\.app/[^/\s]+/issue/[A-Z][A-Z0-9_]+-\d+(?:/[^\s)]*)?}i
  IDENTIFIER_REGEX = %r{/issue/([A-Z][A-Z0-9_]+-\d+)}i

  def perform
    return unless valid_message?

    attempt_link
  end

  private

  def valid_message?
    message.private? && message.content.present? && message.sender.is_a?(User)
  end

  def attempt_link
    linear_url = message.content[LINEAR_URL_REGEX]
    return if linear_url.blank?

    identifier = linear_url[IDENTIFIER_REGEX, 1]&.upcase
    return if identifier.blank? || already_linked?(identifier)

    finalize_link(identifier)
  end

  def finalize_link(identifier)
    node_id = resolve_node_id(identifier)
    return if node_id.blank?
    return unless link_to_linear(node_id, identifier)

    post_activity_message(identifier)
  end

  def already_linked?(identifier)
    response = processor.linked_issues(conversation_link)
    return false if response[:error]

    response[:data].any? { |attachment| attachment.dig('issue', 'identifier') == identifier }
  end

  def resolve_node_id(identifier)
    response = processor.search_issue(identifier)
    return if response[:error]

    node = response[:data].find { |issue| issue['identifier'] == identifier }
    node && node['id']
  end

  def link_to_linear(node_id, identifier)
    title = message.conversation.contact&.name.presence || identifier
    response = processor.link_issue(conversation_link, node_id, title, message.sender)
    response[:error].blank?
  end

  def post_activity_message(identifier)
    Linear::ActivityMessageService.new(
      conversation: message.conversation,
      action_type: :issue_linked,
      user: message.sender,
      issue_data: { id: identifier }
    ).perform
  end

  def conversation_link
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{message.account_id}/conversations/#{message.conversation.display_id}"
  end

  def processor
    @processor ||= Integrations::Linear::ProcessorService.new(account: message.account)
  end
end

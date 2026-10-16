class Integrations::Linear::AutoLinkService
  pattr_initialize [:account!, :message!]

  LINEAR_URL_REGEX = %r{https?://linear\.app/[^/\s]+/issue/[A-Z][A-Z0-9_]+-\d+(?:/[^\s)]*)?}
  IDENTIFIER_REGEX = %r{/issue/([A-Z][A-Z0-9_]+-\d+)}i
  WORKSPACE_REGEX = %r{//linear\.app/([^/\s]+)/}i

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
    workspace = linear_url[WORKSPACE_REGEX, 1]&.downcase
    return if identifier.blank? || workspace.blank? || already_linked?(identifier)

    finalize_link(workspace, identifier)
  end

  def finalize_link(workspace, identifier)
    node_id = resolve_node_id(workspace, identifier)
    return if node_id.blank?
    return unless link_to_linear(node_id, identifier)

    post_activity_message(identifier)
  end

  def already_linked?(identifier)
    response = processor.linked_issues(conversation_link)
    return false if response[:error]

    response[:data].any? { |attachment| attachment.dig('issue', 'identifier') == identifier }
  end

  def resolve_node_id(workspace, identifier)
    response = processor.search_issue(identifier)
    return if response[:error]

    node = response[:data].find do |issue|
      issue['identifier'] == identifier && node_workspace(issue) == workspace
    end
    node && node['id']
  end

  def node_workspace(node)
    node['url']&.match(WORKSPACE_REGEX)&.[](1)&.downcase
  end

  def link_to_linear(node_id, identifier)
    response = processor.link_issue(conversation_link, node_id, attachment_title, message.sender)
    if response[:error].present?
      Rails.logger.warn("[Linear::AutoLinkService] link_issue failed for #{identifier}: #{response[:error]}")
      return false
    end
    true
  end

  def attachment_title
    I18n.t(
      'integration_apps.linear.attachment_link_title',
      conversation_id: message.conversation.display_id,
      name: message.conversation.contact&.name
    )
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
    @processor ||= Integrations::Linear::ProcessorService.new(account: account)
  end
end

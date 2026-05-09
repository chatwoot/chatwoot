class Integrations::Notion::IssueTrackerService
  pattr_initialize [:account!]

  def create_issue(params, user = nil)
    return { error: 'Title is required' } if params[:title].blank?
    return { error: 'Conversation is required' } if params[:conversation_id].blank?

    conversation = account.conversations.find_by!(display_id: params[:conversation_id])
    response = notion_client.post('/pages', page_payload(params, user, conversation))
    return { error: response[:error] } if response[:error]

    issue_link = create_issue_link(response, params, user, conversation)
    { data: serialized_issue_link(issue_link) }
  end

  def linked_issues(conversation_id)
    conversation = account.conversations.find_by!(display_id: conversation_id)
    issue_links = Integrations::IssueLink
                  .where(account: account, conversation: conversation, app_id: 'notion')
                  .order(created_at: :desc, id: :desc)

    { data: issue_links.map { |issue_link| serialized_issue_link(issue_link) } }
  end

  private

  def page_payload(params, user, conversation)
    {
      parent: { data_source_id: issue_tracker_settings['data_source_id'] },
      properties: page_properties(params),
      children: page_children(params, user, conversation)
    }
  end

  def page_properties(params)
    properties = {
      issue_tracker_settings['title_property'] => title_property(params[:title])
    }

    add_description_property(properties, params)
    add_status_property(properties, params)
    add_priority_property(properties, params)
    add_label_property(properties, params)
    properties
  end

  def add_description_property(properties, params)
    property = issue_tracker_settings['description_property']
    return if property.blank? || params[:description].blank?

    properties[property] = rich_text_property(params[:description])
  end

  def add_status_property(properties, params)
    property = issue_tracker_settings['status_property']
    return if property.blank? || params[:state_id].blank?

    properties[property] = { status: { name: params[:state_id] } }
  end

  def add_priority_property(properties, params)
    property = issue_tracker_settings['priority_property']
    return if property.blank? || params[:priority].blank?

    properties[property] = priority_property(params[:priority])
  end

  def add_label_property(properties, params)
    property = issue_tracker_settings['label_property']
    labels = Array(params[:label_ids]).reject(&:blank?)
    return if property.blank? || labels.blank?

    properties[property] = { multi_select: labels.map { |label| { name: label } } }
  end

  def page_children(params, user, conversation)
    children = []
    children << paragraph_block(params[:description]) if params[:description].present?
    children << paragraph_block("Created by #{user.name}") if user
    children << conversation_link_block(conversation)
    children
  end

  def conversation_link_block(conversation)
    conversation_link = conversation_url(conversation)
    {
      object: 'block',
      type: 'paragraph',
      paragraph: {
        rich_text: [
          text('Chatwoot conversation: '),
          text(conversation_link, link: conversation_link)
        ]
      }
    }
  end

  def paragraph_block(content)
    {
      object: 'block',
      type: 'paragraph',
      paragraph: {
        rich_text: [text(content)]
      }
    }
  end

  def title_property(content)
    { title: [text(content)] }
  end

  def rich_text_property(content)
    { rich_text: [text(content)] }
  end

  def priority_property(priority)
    priority_string = priority.to_s
    return { number: priority_string.to_i } if priority_string.match?(/\A\d+\z/)

    { select: { name: priority_string } }
  end

  def text(content, link: nil)
    text = { content: content.to_s }
    text[:link] = { url: link } if link

    {
      type: 'text',
      text: text
    }
  end

  def create_issue_link(response, params, user, conversation)
    Integrations::IssueLink.create!(
      account: account,
      conversation: conversation,
      app_id: 'notion',
      external_id: response[:id],
      external_url: response[:url],
      external_title: params[:title],
      metadata: {
        data_source_id: issue_tracker_settings['data_source_id'],
        created_by: user&.id,
        created_by_name: user&.name
      }
    )
  end

  def serialized_issue_link(issue_link)
    {
      id: issue_link.external_id,
      title: issue_link.external_title,
      url: issue_link.external_url,
      link_id: issue_link.id,
      created_at: issue_link.created_at.iso8601,
      metadata: issue_link.metadata
    }
  end

  def conversation_url(conversation)
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/conversations/#{conversation.display_id}"
  end

  def issue_tracker_settings
    @issue_tracker_settings ||= notion_hook.settings.to_h['issue_tracker'] || {}
  end

  def notion_hook
    @notion_hook ||= account.hooks.find_by!(app_id: 'notion')
  end

  def notion_client
    @notion_client ||= Notion::ApiClient.new(notion_hook.access_token)
  end
end

class ActionService
  include EmailHelper

  def initialize(conversation)
    @conversation = conversation.reload
    @account = @conversation.account
  end

  def mute_conversation(_params)
    @conversation.mute!
  end

  def snooze_conversation(_params)
    @conversation.snoozed!
  end

  def resolve_conversation(_params)
    @conversation.resolved!
  end

  def open_conversation(_params)
    @conversation.open!
  end

  def pending_conversation(_params)
    @conversation.pending!
  end

  def change_status(status)
    @conversation.update!(status: status[0])
  end

  def change_priority(priority)
    @conversation.update!(priority: (priority[0] == 'nil' ? nil : priority[0]))
  end

  def add_label(labels)
    return if labels.empty?

    @conversation.reload.add_labels(labels)
  end

  def assign_agent(agent_ids = [])
    if agent_ids[0] == 'nil'
      return Conversations::AssignmentService.new(conversation: @conversation, assignee_id: nil).perform
    end

    agent_ids = [last_responding_agent_id] if agent_ids[0] == 'last_responding_agent'
    return unless agent_belongs_to_inbox?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)
    return unless @agent.present? && @agent.confirmed?

    Conversations::AssignmentService.new(conversation: @conversation, assignee_id: @agent.id).perform
  end

  def remove_label(labels)
    return if labels.empty?

    labels = @conversation.label_list - labels
    @conversation.update(label_list: labels)
  end

  def assign_team(team_ids = [])
    # Keep nil/0 handling for existing automation and macro payloads.
    should_unassign = team_ids.blank? || %w[nil 0].include?(team_ids[0].to_s)
    if should_unassign
      return Conversations::TeamAssignmentService.new(conversation: @conversation, team_id: nil).perform
    end

    # check if team belongs to account only if team_id is present
    # if team_id is nil, then it means that the team is being unassigned
    return unless !team_ids[0].nil? && team_belongs_to_account?(team_ids)

    Conversations::TeamAssignmentService.new(
      conversation: @conversation,
      team_id: team_ids[0]
    ).perform
  end

  def remove_assigned_agent(_params)
    Conversations::AssignmentService.new(conversation: @conversation, assignee_id: nil).perform
  end

  def remove_assigned_team(_params)
    Conversations::TeamAssignmentService.new(conversation: @conversation, team_id: nil).perform
  end

  def send_email_transcript(emails)
    return unless @account.email_transcript_enabled?

    emails = emails[0].gsub(/\s+/, '').split(',')

    emails.each do |email|
      break unless @account.within_email_rate_limit?

      email = parse_email_variables(@conversation, email)
      ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(@conversation, email)&.deliver_later
      @account.increment_email_sent_count
    end
  end

  def update_contact_custom_attribute(params)
    attribute_key, value = extract_custom_attribute_params(params)
    if attribute_key.blank?
      Rails.logger.warn("[Automation] update_contact_custom_attribute skipped: blank attribute_key params=#{params.inspect}")
      return
    end

    definition = find_writable_custom_attribute(attribute_key, :contact_attribute)
    if definition.blank?
      Rails.logger.warn("[Automation] update_contact_custom_attribute skipped: no contact attribute '#{attribute_key}' on account #{@account.id}")
      return
    end

    contact = @conversation.contact
    attrs = (contact.custom_attributes || {}).merge(
      attribute_key => normalize_custom_attribute_value(definition, value)
    )
    contact.update!(custom_attributes: attrs)
  end

  def update_conversation_custom_attribute(params)
    attribute_key, value = extract_custom_attribute_params(params)
    if attribute_key.blank?
      Rails.logger.warn("[Automation] update_conversation_custom_attribute skipped: blank attribute_key params=#{params.inspect}")
      return
    end

    definition = find_writable_custom_attribute(attribute_key, :conversation_attribute)
    if definition.blank?
      Rails.logger.warn("[Automation] update_conversation_custom_attribute skipped: no conversation attribute '#{attribute_key}' on account #{@account.id}")
      return
    end

    attrs = (@conversation.custom_attributes || {}).merge(
      attribute_key => normalize_custom_attribute_value(definition, value)
    )
    @conversation.update!(custom_attributes: attrs)
  end

  private

  def extract_custom_attribute_params(params)
    data = params.is_a?(Array) ? params[0] : params
    return [nil, nil] if data.blank?

    data = data.with_indifferent_access if data.respond_to?(:with_indifferent_access)
    [data[:attribute_key].to_s, data[:value]]
  end

  def find_writable_custom_attribute(attribute_key, attribute_model)
    @account.custom_attribute_definitions.find_by(
      attribute_key: attribute_key,
      attribute_model: attribute_model
    )
  end

  def normalize_custom_attribute_value(definition, raw_value)
    rendered = render_custom_attribute_template(raw_value)

    case definition.attribute_display_type
    when 'number', 'currency', 'percent'
      Float(rendered)
    when 'checkbox'
      ActiveModel::Type::Boolean.new.cast(rendered)
    when 'date'
      parse_custom_attribute_date(rendered)
    else
      # text, link, list, and any other type
      rendered.to_s
    end
  rescue ArgumentError, TypeError => e
    Rails.logger.warn("[Automation] custom attribute normalize failed for #{definition.attribute_key}: #{e.message}")
    raw_value.to_s
  end

  def render_custom_attribute_template(raw_value)
    text = raw_value.to_s
    return text unless text.include?('{{')

    AutomationRules::MessageRendererService.new(@conversation, text).perform
  end

  def parse_custom_attribute_date(rendered)
    text = rendered.to_s.strip
    return text if text.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.parse(text).iso8601
  end

  def last_responding_agent_id
    @conversation.messages.outgoing.where(sender_type: 'User', private: false).last&.sender_id
  end

  def agent_belongs_to_inbox?(agent_ids)
    member_ids = @conversation.inbox.members.pluck(:user_id)
    assignable_agent_ids = member_ids + @account.administrators.ids

    assignable_agent_ids.include?(agent_ids[0])
  end

  def team_belongs_to_account?(team_ids)
    @account.team_ids.include?(team_ids[0])
  end

  def conversation_a_tweet?
    return false if @conversation.additional_attributes.blank?

    @conversation.additional_attributes['type'] == 'tweet'
  end
end

ActionService.include_mod_with('ActionService')

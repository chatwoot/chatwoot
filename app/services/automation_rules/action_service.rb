class AutomationRules::ActionService < ActionService
  def initialize(rule, account, conversation)
    super(conversation)
    @rule = rule
    @account = account
    Current.executed_by = rule
  end

  def perform
    @rule.actions.each do |action|
      @conversation.reload
      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  def add_label_to_contact(labels)
    return if labels.blank?

    contact = @conversation.contact
    return if contact.blank?

    merged = (contact.label_list + labels).uniq
    return if merged.sort == contact.label_list.sort

    # Suppress the Contact label-propagation callback so this action remains
    # contact-scoped (the action contract). Users who want fan-out to every
    # conversation should pick `add_label_everywhere` instead.
    without_label_propagation { contact.update_labels(merged) }
  end

  def remove_label_from_contact(labels)
    return if labels.blank?

    contact = @conversation.contact
    return if contact.blank?

    remaining = contact.label_list - labels
    return if remaining.sort == contact.label_list.sort

    without_label_propagation { contact.update_labels(remaining) }
  end

  def without_label_propagation
    previous = Current.label_propagation_in_progress
    Current.label_propagation_in_progress = true
    yield
  ensure
    Current.label_propagation_in_progress = previous
  end

  def add_label_everywhere(labels)
    return if labels.blank?

    contact = @conversation.contact
    return if contact.blank?

    contact_merged = (contact.label_list + labels).uniq
    contact.update_labels(contact_merged) unless contact_merged.sort == contact.label_list.sort

    # Only touch open conversations; resolved / pending / snoozed stay frozen.
    contact.conversations.where(status: :open).find_each do |conv|
      conv_merged = (conv.label_list + labels).uniq
      conv.update_labels(conv_merged) unless conv_merged.sort == conv.label_list.sort
    end
  end

  def remove_label_everywhere(labels)
    return if labels.blank?

    contact = @conversation.contact
    return if contact.blank?

    contact_remaining = contact.label_list - labels
    contact.update_labels(contact_remaining) unless contact_remaining.sort == contact.label_list.sort

    contact.conversations.where(status: :open).find_each do |conv|
      conv_remaining = conv.label_list - labels
      conv.update_labels(conv_remaining) unless conv_remaining.sort == conv.label_list.sort
    end
  end

  def inherit_contact_labels(_params = nil)
    contact = @conversation.contact
    return if contact.blank?

    inherited = contact.label_list
    return if inherited.blank?

    merged = (@conversation.label_list + inherited).uniq
    return if merged.sort == @conversation.label_list.sort

    @conversation.update_labels(merged)
  end

  def sync_conversation_labels_everywhere(_params = nil)
    contact = @conversation.contact
    return if contact.blank?

    conv_labels = @conversation.label_list.to_a
    return if conv_labels.empty?

    sync_contact_with_labels(contact, conv_labels)
    fan_labels_to_open_siblings(contact, conv_labels)
  end

  def sync_contact_with_labels(contact, labels)
    next_contact = (contact.label_list + labels).uniq
    contact.update_labels(next_contact) unless next_contact.sort == contact.label_list.sort
  end

  def fan_labels_to_open_siblings(contact, labels)
    contact.conversations.where(status: :open).where.not(id: @conversation.id).find_each do |sib|
      next_sib = (sib.label_list + labels).uniq
      sib.update_labels(next_sib) unless next_sib.sort == sib.label_list.sort
    end
  end

  def send_attachment(blob_ids)
    return if conversation_a_tweet?

    return unless @rule.files.attached?

    blobs = ActiveStorage::Blob.where(id: blob_ids)

    return if blobs.blank?

    params = { content: nil, private: false, attachments: blobs }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: "automation_event.#{@rule.event_name}")
    WebhookJob.perform_later(webhook_url[0], payload)
  end

  def send_message(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: false, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def add_private_note(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: true, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation.reload, params).perform
  end

  def send_email_to_team(params)
    teams = Team.where(id: params[0][:team_ids])

    teams.each do |team|
      break unless @account.within_email_rate_limit?

      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
      @account.increment_email_sent_count
    end
  end
end

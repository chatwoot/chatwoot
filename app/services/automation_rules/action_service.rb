class AutomationRules::ActionService < ActionService
  def initialize(rule, account, conversation)
    super(conversation)
    @rule = rule
    @account = account
    Current.executed_by = rule
  end

  def perform
    # The activity messages the actions trigger are rendered as each change commits, in the thread's
    # locale. A rule runs in Sidekiq, where that is the locale of whoever enqueued the event (English
    # for an inbound message) or the process default, so the account's is named here. No
    # InvalidLocale guard: `locale` is an enum over LANGUAGES_CONFIG, all of it loaded.
    I18n.with_locale(@account.locale) do
      # Taken once, before the first action: the text of every action of this run reads the same
      # picture, and reads it even after the actions that erase what it shows already ran.
      Current.conversation_snapshot = ConversationSnapshot.new(@conversation)

      @rule.actions.each do |action|
        @conversation.reload
        action = action.with_indifferent_access
        begin
          send(action[:action_name], action[:action_params])
        rescue StandardError => e
          ChatwootExceptionTracker.new(e, account: @account).capture_exception
        end
      end
    end
  ensure
    Current.reset
  end

  private

  def send_attachment(blob_ids)
    return if conversation_a_tweet?

    blobs = @rule.files.blobs.where(id: blob_ids)

    return if blobs.blank?

    params = { content: nil, private: false, attachments: blobs, content_attributes: { automation_rule_id: @rule.id } }
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
    teams = @account.teams.where(id: params[0][:team_ids])

    teams.each do |team|
      break unless @account.within_email_rate_limit?

      TeamNotifications::AutomationNotificationMailer.with(account: @account)
                                                     .conversation_creation(@conversation, team, params[0][:message])&.deliver_now
      @account.increment_email_sent_count
    end
  end

  def scheduled_message_attachment_blob(blob_id)
    return if blob_id.blank?

    attachment = @rule.files.find { |file| file.blob_id == blob_id.to_i }
    attachment&.blob
  end
end

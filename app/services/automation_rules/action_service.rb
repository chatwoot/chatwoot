class AutomationRules::ActionService < ActionService
  def initialize(rule, account, conversation, contact, params)
    super(conversation, contact)
    @rule = rule
    @account = account
    @params = params
    Current.executed_by = rule
  end

  def perform
    @rule.actions.each do |action|
      @conversation&.reload

      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
    increment_trigger_count
  ensure
    Current.reset
  end

  private

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

  def send_template(template_params)
    template = template_params[0]

    channel = find_channel_by_inbox(template['inbox_id'])
    contact = @conversation.nil? ? @contact : @conversation.contact
    processed_params = processed_variable_params(template['processed_params'], template['processed_events'])

    processed_template = {
      name: template['name'],
      namespace: template['namespace'],
      lang_code: template['language'],
      parameters: processed_params&.map { |_, value| { type: 'text', text: value } }
    }

    channel.send_template(contact.phone_number, processed_template)
  end

  def send_email_to_team(params)
    teams = Team.where(id: params[0][:team_ids])

    teams.each do |team|
      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
    end
  end

  def find_channel_by_inbox(inbox_id)
    inbox = Inbox.find(inbox_id)
    Channel::Whatsapp.find(inbox.channel_id)
  end

  def increment_trigger_count
    @rule.increment!(:trigger_count)
  end

  def processed_variable_params(processed_params, processed_events)
    processed_events&.each do |key, variable|
      next unless processed_params[key.to_s]

      processed_params[key.to_s] = fetch_variable_value(variable['value'])
    end

    processed_params
  end

  def fetch_variable_value(variable)
    object, attribute = variable.split('.', 2)

    case object
    when 'order'
      @params[attribute]
    when 'contact'
      fetch_value_from_contact(attribute)
    when 'conversation'
      fetch_value_from_object(@conversation, attribute)
    when 'cart'
      fetch_value_from_cart(attribute)
    when 'link'

    end
  end

  def fetch_value_from_object(obj, attribute)
    obj.send(attribute) if obj.respond_to?(attribute)
  end

  def fetch_value_from_contact(attribute)
    return @contact.additional_attributes['shipping_address'] if attribute == 'address'

    @contact.send(attribute) if @contact.respond_to?(attribute)
  end

  def fetch_value_from_cart(attribute)
    return unless attribute == 'items'

    @params.filter_map do |item|
      product_name = item.dig('variant', 'product', 'title')
      attributes = item['attributes']

      cover_color = attributes.find { |attr| attr['key'] == 'coverColor' }&.dig('value')
      number_of_photos = attributes.find { |attr| attr['key'] == 'numberOfPhotos' }&.dig('value')

      "#{product_name} - #{cover_color} - #{number_of_photos} fotos"
    end.compact.join(', ')
  end
end

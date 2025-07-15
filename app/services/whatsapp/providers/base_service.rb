#######################################
# To create a whatsapp provider
# - Inherit this as the base class.
# - Implement `send_message` method in your child class.
# - Implement `send_template_message` method in your child class.
# - Implement `sync_templates` method in your child class.
# - Implement `validate_provider_config` method in your child class.
# - Use Childclass.new(whatsapp_channel: channel).perform.
######################################

class Whatsapp::Providers::BaseService
  pattr_initialize [:whatsapp_channel!]

  def send_message(_phone_number, _message)
    raise 'Overwrite this method in child class'
  end

  def send_template(_phone_number, _template_info)
    raise 'Overwrite this method in child class'
  end

  def sync_template
    raise 'Overwrite this method in child class'
  end

  def validate_provider_config
    raise 'Overwrite this method in child class'
  end

  def error_message
    raise 'Overwrite this method in child class'
  end

  def process_response(response)
    parsed_response = response.parsed_response
    if response.success? && parsed_response['error'].blank?
      parsed_response['messages'].first['id']
    else
      handle_error(response)
      nil
    end
  end

  def handle_error(response)
    Rails.logger.error response.body

    # Check for authentication errors that require reauthorization
    check_for_authentication_error(response)

    return if @message.blank?

    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/#sample-response
    error_message = error_message(response)
    return if error_message.blank?

    @message.external_error = error_message
    @message.status = :failed
    @message.save!
  end

  def check_for_authentication_error(response)
    parsed_response = response.parsed_response
    return unless parsed_response && parsed_response['error']

    error = parsed_response['error']
    error_code = error['code']
    error_subcode = error['error_subcode']

    # Check for authentication related errors
    # Error code 190: Access token expired/invalid
    # Error subcodes: 463 (expired token), 467 (invalid token)
    return unless error_code == 190 || [463, 467].include?(error_subcode)

    Rails.logger.error "[WHATSAPP] Authentication error detected: #{error['message']}"
    whatsapp_channel.authorization_error!
  end

  def create_buttons(items)
    buttons = []
    items.each do |item|
      button = { :type => 'reply', 'reply' => { 'id' => item['value'], 'title' => item['title'] } }
      buttons << button
    end
    buttons
  end

  def create_rows(items)
    rows = []
    items.each do |item|
      row = { 'id' => item['value'], 'title' => item['title'] }
      rows << row
    end
    rows
  end

  def create_payload(type, message_content, action)
    {
      'type': type,
      'body': {
        'text': message_content
      },
      'action': action
    }
  end

  def create_payload_based_on_items(message)
    if message.content_attributes['items'].length <= 3
      create_button_payload(message)
    else
      create_list_payload(message)
    end
  end

  def create_button_payload(message)
    buttons = create_buttons(message.content_attributes['items'])
    json_hash = { 'buttons' => buttons }
    create_payload('button', message.outgoing_content, JSON.generate(json_hash))
  end

  def create_list_payload(message)
    rows = create_rows(message.content_attributes['items'])
    section1 = { 'rows' => rows }
    sections = [section1]
    json_hash = { :button => I18n.t('conversations.messages.whatsapp.list_button_label'), 'sections' => sections }
    create_payload('list', message.outgoing_content, JSON.generate(json_hash))
  end
end

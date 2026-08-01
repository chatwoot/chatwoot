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
  WHATSAPP_BUTTON_TITLE_MAX_LENGTH = 20

  def send_message(_phone_number, _message)
    raise 'Overwrite this method in child class'
  end

  def send_template(_phone_number, _template_info, _message)
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

  def process_response(response, message)
    parsed_response = response.parsed_response
    if response.success? && parsed_response['error'].blank?
      parsed_response['messages'].first['id']
    else
      handle_error(response, message)
      nil
    end
  end

  def handle_error(response, message)
    Rails.logger.error response.body
    return if message.blank?

    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/#sample-response
    error_message = error_message(response)
    return if error_message.blank?

    message.external_error = error_message
    message.status = :failed
    message.save!
  end

  # WhatsApp coexistence / username migration: a contact may become addressable only by a Business-Scoped
  # User ID (BSUID, e.g. "BR.123..."), with no phone number available. The Cloud API requires a BSUID to be
  # passed in the `recipient` field (with recipient_type: individual), NOT in `to`. Passing a BSUID in `to`
  # returns HTTP 200 with a message id but the message is silently dropped: the "CC." prefix is stripped and
  # the remainder is treated as a phone number (wa_id), which never resolves. Phone numbers keep using `to`.
  # See: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids/
  def recipient_params(identifier)
    if identifier.to_s.match?(RegexHelper::WHATSAPP_BSUID_REGEX)
      { recipient_type: 'individual', recipient: identifier }
    else
      { to: identifier }
    end
  end

  def create_buttons(items)
    buttons = []
    items.each do |item|
      button = {
        :type => 'reply',
        'reply' => {
          'id' => item['value'],
          'title' => normalize_whatsapp_button_title(item['title'])
        }
      }
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
    create_payload('button', message.outgoing_content, json_hash)
  end

  def create_list_payload(message)
    rows = create_rows(message.content_attributes['items'])
    section1 = { 'rows' => rows }
    sections = [section1]
    json_hash = { :button => I18n.t('conversations.messages.whatsapp.list_button_label'), 'sections' => sections }
    create_payload('list', message.outgoing_content, json_hash)
  end

  def create_carousel_payload(message)
    Whatsapp::CarouselPayloadBuilder.new(message).perform
  end

  def create_cta_url_payload(message)
    Whatsapp::CtaUrlPayloadBuilder.new(message).perform
  end

  def create_interactive_buttons_payload(message)
    Whatsapp::InteractiveButtonsPayloadBuilder.new(message).perform
  end

  def create_interactive_list_payload(message)
    Whatsapp::InteractiveListPayloadBuilder.new(message).perform
  end

  def interactive_buttons_message?(message)
    message.content_type == 'interactive_buttons'
  end

  def interactive_list_message?(message)
    message.content_type == 'interactive_list'
  end

  def interactive_cta_url_message?(message)
    message.content_type == 'cta_url'
  end

  def interactive_carousel_message?(message)
    return false unless message.content_type == 'cards'

    Array(message.content_attributes['items']).flat_map do |item|
      Array(item['actions'] || item[:actions]).filter_map do |action|
        action['type'] || action[:type]
      end
    end.intersect?(%w[url reply])
  end

  def normalize_whatsapp_button_title(title)
    title.to_s.strip.first(WHATSAPP_BUTTON_TITLE_MAX_LENGTH)
  end
end

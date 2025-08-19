class Whatsapp::CampaignLiquidProcessorService
  pattr_initialize [:campaign!, :contact!]

  def call(template_params)
    return template_params if template_params.blank? || template_params['processed_params'].blank?

    processed_template_params = template_params.deep_dup
    processed_template_params['processed_params'] = process_liquid_in_hash(template_params['processed_params'])
    processed_template_params
  end

  private

  def process_liquid_in_hash(hash)
    return hash unless hash.is_a?(Hash)

    hash.transform_values { |value| process_liquid_value(value) }
  end

  def process_liquid_value(value)
    case value
    when String
      process_liquid_string(value)
    when Hash
      process_liquid_in_hash(value)
    when Array
      process_liquid_array(value)
    else
      value
    end
  end

  def process_liquid_array(array)
    array.map { |item| process_liquid_value(item) }
  end

  def process_liquid_string(string)
    return string if string.blank?

    template = Liquid::Template.parse(string)
    template.render(message_drops)
  rescue Liquid::Error
    string
  end

  def message_drops
    {
      'contact' => ContactDrop.new(contact),
      'agent' => UserDrop.new(campaign.sender),
      'inbox' => InboxDrop.new(campaign.inbox),
      'account' => AccountDrop.new(campaign.account)
    }
  end
end

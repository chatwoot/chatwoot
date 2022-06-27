class Whatsapp::Providers::WhatsappCloudService < Whatsapp::Providers::BaseService
  def send_message(_phone_number, _message)
    raise 'Overwrite this method in child class'
  end

  def send_template(_phone_number, _template_info)
    raise 'Overwrite this method in child class'
  end

  def sync_templates
    raise 'Overwrite this method in child class'
  end

  def validate_provider_config
    nil
  end
end

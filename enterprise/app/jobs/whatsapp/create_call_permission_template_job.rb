# Creates the template a WhatsApp number's call permission requests go out as outside the 24h window
class Whatsapp::CreateCallPermissionTemplateJob < ApplicationJob
  queue_as :low

  def perform(channel)
    return unless channel.voice_enabled?

    Whatsapp::CallPermissionTemplate.new(channel).create!
  end
end

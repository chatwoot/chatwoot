# frozen_string_literal: true

module Igaralead::ContactInboxBuilder
  private

  def generate_source_id
    case @inbox.channel_type
    when 'Channel::BaileysWhatsapp'
      baileys_wa_source_id
    else
      super
    end
  end

  def baileys_wa_source_id
    raise ActionController::ParameterMissing, 'contact phone number' unless @contact.phone_number

    "#{@contact.phone_number.delete('+')}@s.whatsapp.net"
  end

  def new_source_id
    if @inbox.respond_to?(:baileys_whatsapp?) && @inbox.baileys_whatsapp?
      "whatsapp:#{@source_id}#{rand(100)}"
    else
      super
    end
  end

  def allowed_channels?
    (@inbox.respond_to?(:baileys_whatsapp?) && @inbox.baileys_whatsapp?) || super
  end
end

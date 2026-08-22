# Receives Cloud-shaped WhatsApp payloads from the Baileys companion bridge
# (see whatsapp-companion/ + PLAN.md). The companion authenticates with the
# shared companion token (x-companion-token header, see Whatsapp::CompanionConfig).
# We then reuse the existing Webhooks::WhatsappEventsJob, which routes unofficial
# channels to the Whatsapp::IncomingMessageWhatsappCloudService parser.

class Webhooks::WhatsappUnofficialController < ActionController::API
  before_action :authenticate_companion!

  def process_payload
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    if channel.blank?
      Rails.logger.warn("Rejected unofficial WhatsApp webhook for unknown number: #{params[:phone_number]}")
      return head :not_found
    end

    Webhooks::WhatsappEventsJob.perform_later(payload_params)
    head :ok
  end

  private

  def authenticate_companion!
    expected = Whatsapp::CompanionConfig.companion_token
    return head :unauthorized if expected.blank?

    provided = request.headers['x-companion-token'].to_s
    return if ActiveSupport::SecurityUtils.secure_compare(expected, provided)

    head :unauthorized
  end

  # The WhatsApp Cloud API payload is deeply nested and dynamic (contacts,
  # messages, status arrays, metadata). There is no practical way to express
  # the full shape with static permit keys, so we forward the entire payload
  # through the Strong Parameters API.  The companion-token guard above is
  # the security boundary for this endpoint.
  def payload_params
    params.to_unsafe_hash.with_indifferent_access
  end
end

class Webhooks::WhapiController < ActionController::API
  before_action :verify_webhook_signature, if: :verify_signature?
  
  def callback
    process_webhook
    head :ok
  end
  
  private
  
  def process_webhook
    # Queue the job to process this webhook
    Webhooks::WhatsappEventsJob.perform_later(permitted_params.to_h.deep_symbolize_keys)
  end
  
  def verify_webhook_signature
    provided_signature = request.headers['X-Whapi-Signature'] || ''
    
    # Get phone number from the request
    phone_number = params[:phone_number] || params.dig(:receiver) || ''
    
    # Find the channel
    channel = Channel::Whatsapp.find_by(phone_number: phone_number, provider: 'whapi')
    return head :unauthorized if channel.blank?
    
    # Compute expected signature
    webhook_secret = channel.provider_config['webhook_secret'] || ''
    computed_signature = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, request.raw_post)
    
    # Compare signatures
    unless ActiveSupport::SecurityUtils.secure_compare(provided_signature, computed_signature)
      head :unauthorized
    end
  end
  
  def verify_signature?
    # Whapi requires signature verification
    true
  end
  
  def permitted_params
    params.permit!
  end
end
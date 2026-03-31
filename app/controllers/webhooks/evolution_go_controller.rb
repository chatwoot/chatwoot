class Webhooks::EvolutionGoController < ActionController::API
  def process_payload
    channel = evolution_channel
    return render json: { error: 'Unknown Evolution Go instance' }, status: :not_found if channel.blank?
    return render json: { error: 'Invalid Evolution Go webhook token' }, status: :unauthorized unless valid_instance_token?(channel)

    Webhooks::EvolutionGoJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def evolution_channel
    instance_name = params[:instanceName] || params[:instance]
    return if instance_name.blank?

    Channel::Whatsapp.where(provider: 'evolution_go')
                     .find_by("provider_config ->> 'instance_name' = ?", instance_name)
  end

  def valid_instance_token?(channel)
    provided_token = params[:instanceToken].to_s
    expected_token = EvolutionGo::Client.instance_token(channel.provider_config['instance_name']).to_s
    return false if provided_token.blank? || expected_token.blank?
    return false unless provided_token.bytesize == expected_token.bytesize

    ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)
  rescue EvolutionGo::Client::ConfigurationError
    false
  end
end

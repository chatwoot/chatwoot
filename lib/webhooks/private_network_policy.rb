class Webhooks::PrivateNetworkPolicy
  def initialize(webhook_type)
    @webhook_type = webhook_type.to_s
  end

  def safe_fetch_options
    return {} unless allowed_type?
    return {} if allowed_private_hosts.blank? && allowed_private_cidrs.blank?

    {
      allowed_private_hosts: allowed_private_hosts,
      allowed_private_cidrs: allowed_private_cidrs
    }
  end

  private

  attr_reader :webhook_type

  def allowed_type?
    allowed_types.include?(webhook_type)
  end

  def allowed_types
    env_list('WEBHOOK_PRIVATE_NETWORK_ALLOWED_TYPES')
  end

  def allowed_private_hosts
    env_list('WEBHOOK_ALLOWED_PRIVATE_HOSTS')
  end

  def allowed_private_cidrs
    env_list('WEBHOOK_ALLOWED_PRIVATE_CIDRS')
  end

  def env_list(key)
    ENV.fetch(key, '').split(',').map(&:strip).compact_blank
  end
end

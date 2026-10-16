class Platform::Api::V1::EmailChannelMigrationsController < PlatformController
  before_action :set_account
  before_action :validate_account_permissible
  before_action :validate_feature_flag
  before_action :validate_params

  def create
    results = migrate_email_channels
    render json: { results: results }, status: :ok
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def validate_account_permissible
    return if @platform_app.platform_app_permissibles.find_by(permissible: @account)

    render json: { error: 'Non permissible resource' }, status: :unauthorized
  end

  def validate_feature_flag
    return if ActiveModel::Type::Boolean.new.cast(ENV.fetch('EMAIL_CHANNEL_MIGRATION', false))

    render json: { error: 'Email channel migration is not enabled' }, status: :forbidden
  end

  def validate_params
    return render json: { error: 'Missing migrations parameter' }, status: :unprocessable_entity if migration_params.blank?

    return unless migration_params.size > MAX_MIGRATIONS

    return render json: { error: "Too many migrations (max #{MAX_MIGRATIONS})" },
                  status: :unprocessable_entity
  end

  def migrate_email_channels
    migration_params.map { |entry| migrate_single(entry) }
  end

  MAX_MIGRATIONS = 25
  SUPPORTED_PROVIDERS = %w[google microsoft].freeze

  def migrate_single(entry)
    validate_provider!(entry[:provider])

    ActiveRecord::Base.transaction do
      channel = create_channel(entry)
      inbox = create_inbox(channel, entry)

      { email: entry[:email], inbox_id: inbox.id, channel_id: channel.id, status: 'success' }
    end
  rescue StandardError => e
    { email: entry[:email], status: 'error', message: e.message }
  end

  def create_channel(entry)
    Channel::Email.create!(
      account_id: @account.id,
      email: entry[:email],
      provider: entry[:provider],
      provider_config: entry[:provider_config]&.to_h,
      imap_enabled: entry.fetch(:imap_enabled, true),
      imap_address: entry[:imap_address] || default_imap_address(entry[:provider]),
      imap_port: entry[:imap_port] || 993,
      imap_login: entry[:imap_login] || entry[:email],
      imap_enable_ssl: entry.fetch(:imap_enable_ssl, true)
    )
  end

  def create_inbox(channel, entry)
    @account.inboxes.create!(
      name: entry[:inbox_name] || "Migrated #{entry[:provider]&.capitalize}: #{entry[:email]}",
      channel: channel
    )
  end

  def validate_provider!(provider)
    return if SUPPORTED_PROVIDERS.include?(provider)

    raise ArgumentError, "Unsupported provider '#{provider}'. Must be one of: #{SUPPORTED_PROVIDERS.join(', ')}"
  end

  def default_imap_address(provider)
    case provider
    when 'google' then 'imap.gmail.com'
    when 'microsoft' then 'outlook.office365.com'
    else ''
    end
  end

  def migration_params
    params.permit(migrations: [
                    :email, :provider, :inbox_name,
                    :imap_enabled, :imap_address, :imap_port, :imap_login, :imap_enable_ssl,
                    { provider_config: {} }
                  ])[:migrations]
  end
end

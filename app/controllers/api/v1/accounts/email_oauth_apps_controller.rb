# Cadastro POR CONTA das credenciais do app OAuth de e-mail (Azure/Google).
# Admin-only. O secret nunca é devolvido ao cliente (só se está configurado).
class Api::V1::Accounts::EmailOauthAppsController < Api::V1::Accounts::BaseController
  before_action :ensure_admin
  before_action :validate_provider

  def show
    resolver = ::EmailOauth::CredentialResolver.new(Current.account, provider)
    creds = resolver.credentials
    app = account_app

    render json: {
      provider: provider,
      configured: resolver.configured?,
      source: creds[:source],
      client_id: app&.client_id,
      redirect_uri: app&.redirect_uri,
      tenant_id: app&.tenant_id,
      callback_url: "#{base_url}/#{provider}/callback"
    }
  end

  def update
    app = Current.account.email_oauth_apps.find_or_initialize_by(provider: provider)
    app.assign_attributes(permitted_params)
    app.save!

    render json: { provider: provider, configured: true }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def destroy
    account_app&.destroy
    head :ok
  end

  private

  def provider
    params[:provider].to_s
  end

  def account_app
    @account_app ||= Current.account.email_oauth_apps.find_by(provider: provider)
  end

  def validate_provider
    return if AccountEmailOauthApp::PROVIDERS.include?(provider)

    render json: { error: 'invalid_provider' }, status: :unprocessable_entity
  end

  def ensure_admin
    raise Pundit::NotAuthorizedError unless Current.account_user&.administrator?
  end

  def permitted_params
    params.permit(:client_id, :client_secret, :redirect_uri, :tenant_id)
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end

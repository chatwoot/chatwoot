class Shopify::InstallationService
  def initialize(account:, pending_installation:)
    @account = account
    @pending_installation = pending_installation
  end

  def perform
    @pending_installation.with_current_installation { install_hook }
  end

  private

  def install_hook
    data = @pending_installation.data
    raise_duplicate_shop! if shopify_shop_exists?(data['shop'])

    hook = create_shopify_hook(data)
    @pending_installation.consume!
  rescue Shopify::PendingInstallation::CommitOutcomeUnknown
    raise
  rescue ActiveRecord::RecordNotUnique
    raise_duplicate_shop!
  rescue ActiveRecord::RecordInvalid => e
    raise unless e.record.is_a?(Integrations::Hook) && e.record.errors.added?(:reference_id, :taken)

    raise_duplicate_shop!
  rescue StandardError
    hook&.destroy!
    raise
  end

  def create_shopify_hook(data)
    @account.hooks.create!(
      app_id: 'shopify',
      access_token: data['access_token'],
      status: 'enabled',
      reference_id: data['shop'],
      settings: {
        scope: data['scope'],
        connected_at: data.fetch('connected_at'),
        installation_id: SecureRandom.uuid
      }
    )
  end

  def shopify_shop_exists?(shop)
    Integrations::Hook.where(app_id: 'shopify').exists?(['LOWER(reference_id) = ?', shop.downcase])
  end

  def raise_duplicate_shop!
    raise Shopify::PendingInstallation::DuplicateShop, 'This Shopify store is already connected'
  end
end

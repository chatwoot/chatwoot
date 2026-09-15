# frozen_string_literal: true

class Shopify::SignupService < AccountBuilder
  def initialize(shopify_pending_install_token:, **attributes)
    super(**attributes)
    @shopify_pending_install_token = shopify_pending_install_token
  end

  def perform
    reject_existing_user_for_shopify_signup
    if @user.nil?
      validate_email
      validate_user
    end
    claim_shopify_installation

    @pending_installation.with_current_installation { create_shopify_signup }
  rescue StandardError => e
    return recover_committed_shopify_signup(e) if committed_shopify_signup?

    @pending_installation&.release!(unbind: true)
    raise
  end

  private

  def create_shopify_signup
    transaction_succeeded = ActiveRecord::Base.transaction do
      @account = create_account
      bind_shopify_installation
      @user = create_and_link_user
      true
    end
    raise ActiveRecord::Rollback unless transaction_succeeded

    finalize_shopify_signup
    [@user, @account]
  end

  def reject_existing_user_for_shopify_signup
    return if @user.blank?

    raise UserExists.new(email: @user.email)
  end

  def create_account
    attributes = {
      name: account_name,
      locale: I18n.locale,
      custom_attributes: account_custom_attributes
    }
    attributes[:internal_attributes] = shopify_billing_identity

    # billing_provider and signup_source are fixed classification labels, not sensitive values.
    # codeql[rb/clear-text-storage-sensitive-data]
    @account = Account.create!(attributes)
    Current.account = @account
  end

  def account_custom_attributes
    attributes = { 'onboarding_step' => 'account_details' }
    attributes['subscription_status'] = 'pending'
    attributes
  end

  def shopify_billing_identity
    {
      'billing_provider' => 'shopify',
      'signup_source' => 'shopify'
    }
  end

  def claim_shopify_installation
    raise Shopify::PendingInstallation::FeatureDisabled, 'Shopify signup is unavailable' unless Shopify::FeatureGate.enabled?

    @pending_installation = Shopify::PendingInstallation.claim(token: @shopify_pending_install_token)
  end

  def bind_shopify_installation
    return unless @pending_installation
    raise Shopify::PendingInstallation::FeatureDisabled, 'Shopify signup is unavailable' unless Shopify::FeatureGate.globally_enabled?

    @pending_installation.bind_to_account!(@account.id)
    @account.enable_features(Shopify::FeatureGate::ACCOUNT_FEATURE)
    @account.save!
    create_shopify_hook
  end

  def create_shopify_hook
    data = @pending_installation.data
    raise_duplicate_shop! if shopify_shop_exists?(data['shop'])

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
  rescue ActiveRecord::RecordNotUnique
    raise_duplicate_shop!
  rescue ActiveRecord::RecordInvalid => e
    raise unless e.record.is_a?(Integrations::Hook) && e.record.errors.added?(:reference_id, :taken)

    raise_duplicate_shop!
  end

  def shopify_shop_exists?(shop)
    Integrations::Hook.where(app_id: 'shopify').exists?(['LOWER(reference_id) = ?', shop.downcase])
  end

  def raise_duplicate_shop!
    raise Shopify::PendingInstallation::DuplicateShop, 'This Shopify store is already connected'
  end

  def finalize_shopify_installation
    @pending_installation&.consume!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
  end

  def committed_shopify_signup?
    return false unless committed_shopify_record_ids?

    Account.exists?(@account.id) &&
      AccountUser.exists?(account_id: @account.id, user_id: @user.id) &&
      NotificationSetting.exists?(account_id: @account.id, user_id: @user.id) &&
      Integrations::Hook.exists?(account_id: @account.id, app_id: 'shopify')
  end

  def committed_shopify_record_ids?
    @pending_installation && @account&.id && @user&.id
  end

  def recover_committed_shopify_signup(error)
    ChatwootExceptionTracker.new(error, account: @account).capture_exception
    finalize_shopify_signup
    [@user, @account]
  end

  def finalize_shopify_signup
    send_shopify_confirmation_instructions
    finalize_shopify_installation
  end

  def send_shopify_confirmation_instructions
    return unless @pending_installation && @user && !@user.confirmed?

    @user.send_confirmation_instructions
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
  end

  def build_user
    super.tap(&:skip_confirmation_notification!)
  end
end

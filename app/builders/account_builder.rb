# frozen_string_literal: true

class AccountBuilder
  include CustomExceptions::Account
  pattr_initialize [
    :account_name,
    :email!,
    :confirmed,
    :user,
    :user_full_name,
    :user_password,
    :super_admin,
    :locale,
    :shopify_pending_install_token
  ]

  def perform
    reject_existing_user_for_shopify_signup
    if @user.nil?
      validate_email
      validate_user
    end
    claim_shopify_installation

    transaction_succeeded = ActiveRecord::Base.transaction do
      @account = create_account
      bind_shopify_installation
      @user = create_and_link_user
      true
    end
    raise ActiveRecord::Rollback unless transaction_succeeded

    finalize_shopify_signup
    [@user, @account]
  rescue StandardError => e
    return recover_committed_shopify_signup(e) if committed_shopify_signup?

    @pending_installation&.release!
    raise
  end

  private

  def user_full_name
    # the empty string ensures that not-null constraint is not violated
    @user_full_name || ''
  end

  def account_name
    # the empty string ensures that not-null constraint is not violated
    @account_name || ''
  end

  def validate_email
    Account::SignUpEmailValidationService.new(@email).perform
  end

  def validate_user
    if User.exists?(email: @email)
      raise UserExists.new(email: @email)
    else
      true
    end
  end

  def reject_existing_user_for_shopify_signup
    return unless @user.present? && shopify_signup?

    raise UserExists.new(email: @user.email)
  end

  def create_account
    attributes = {
      name: account_name,
      locale: I18n.locale,
      custom_attributes: account_custom_attributes
    }
    attributes[:internal_attributes] = shopify_billing_identity if shopify_signup?

    @account = Account.create!(attributes)
    Current.account = @account
  end

  def account_custom_attributes
    attributes = { 'onboarding_step' => 'account_details' }
    attributes['subscription_status'] = 'pending' if shopify_signup?
    attributes
  end

  def shopify_billing_identity
    {
      'billing_provider' => 'shopify',
      'signup_source' => 'shopify'
    }
  end

  def claim_shopify_installation
    return unless shopify_signup?
    raise Shopify::PendingInstallation::FeatureDisabled, 'Shopify signup is unavailable' unless Shopify::FeatureGate.enabled?

    @pending_installation = Shopify::PendingInstallation.claim(token: @shopify_pending_install_token)
  end

  def bind_shopify_installation
    return unless @pending_installation
    raise Shopify::PendingInstallation::FeatureDisabled, 'Shopify signup is unavailable' unless Shopify::FeatureGate.globally_enabled?

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
        connected_at: Time.current.utc.iso8601(6),
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

  def shopify_signup?
    @shopify_pending_install_token.present?
  end

  def create_and_link_user
    if @user.present? || create_user
      link_user_to_account(@user, @account)
      @user
    else
      raise UserErrors.new(errors: @user.errors)
    end
  end

  def link_user_to_account(user, account)
    AccountUser.create!(
      account_id: account.id,
      user_id: user.id,
      role: AccountUser.roles['administrator']
    )
  end

  def create_user
    @user = User.new(email: @email,
                     password: user_password,
                     password_confirmation: user_password,
                     name: user_full_name)
    @user.type = 'SuperAdmin' if @super_admin
    @user.confirm if @confirmed
    @user.skip_confirmation_notification! if shopify_signup?
    @user.save!
  end
end

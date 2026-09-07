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
    if @user.nil?
      validate_email
      validate_user
    end
    claim_shopify_installation
    ActiveRecord::Base.transaction do
      @account = create_account
      @user = create_and_link_user
      bind_shopify_installation
    end
    finalize_shopify_installation
    [@user, @account]
  rescue StandardError => e
    @pending_installation&.release!(unbind: true)
    Rails.logger.debug e.inspect
    raise e
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

  def create_account
    @account = Account.create!(
      name: account_name,
      locale: I18n.locale,
      custom_attributes: { 'onboarding_step' => 'account_details' }
    )
    Current.account = @account
  end

  def claim_shopify_installation
    return if @shopify_pending_install_token.blank?

    @pending_installation = Shopify::PendingInstallation.claim(token: @shopify_pending_install_token)
  end

  def bind_shopify_installation
    return unless @pending_installation

    @pending_installation.bind_to_account!(@account.id)
    data = @pending_installation.data
    @account.hooks.create!(
      app_id: 'shopify',
      access_token: data['access_token'],
      status: 'enabled',
      reference_id: data['shop'],
      settings: { scope: data['scope'] }
    )
  end

  def finalize_shopify_installation
    @pending_installation&.consume!
  rescue Shopify::PendingInstallation::Error => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
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
    @user.save!
  end
end

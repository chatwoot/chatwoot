# frozen_string_literal: true

class AccountBuilder
  include CustomExceptions::Account
  pattr_initialize [:account_name, :email!, :confirmed, :user, :user_full_name, :user_password, :super_admin, :locale]

  def perform
    if @user.nil?
      validate_email
      validate_user
    end
    ActiveRecord::Base.transaction do
      @account = create_account
      @user = create_and_link_user
    end
    [@user, @account]
  rescue StandardError => e
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
    raise InvalidEmail.new({ domain_blocked: domain_blocked }) if domain_blocked?

    address = ValidEmail2::Address.new(@email)
    if address.valid? && !address.disposable?
      true
    else
      raise InvalidEmail.new({ valid: address.valid?, disposable: address.disposable? })
    end
  end

  def validate_user
    if User.exists?(email: @email)
      raise UserExists.new(email: @email)
    else
      true
    end
  end

  def create_account
    @account = Account.create!(name: account_name, locale: I18n.locale)
    Current.account = @account
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

  def domain_blocked?
    domain = @email.split('@').last

    blocked_domains.each do |blocked_domain|
      return true if domain.match?(blocked_domain)
    end

    false
  end

  def blocked_domains
    domains = GlobalConfigService.load('BLOCKED_EMAIL_DOMAINS', '')
    return [] if domains.blank?

    domains.split("\n").map(&:strip)
  end
end

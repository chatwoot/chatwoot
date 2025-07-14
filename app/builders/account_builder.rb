# frozen_string_literal: true

class AccountBuilder
  include CustomExceptions::Account
  include BillingPlans
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
    @account = Account.new(name: account_name, locale: I18n.locale)
    set_initial_trial_plan
    @account.save!
    add_store_id_to_account
    Current.account = @account
    @account
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

  def set_initial_trial_plan
    trial_plan_name = 'free_trial'
    plan_details = self.class.plan_details(trial_plan_name)
    return unless plan_details

    expires_in_days = plan_details.dig('trial_expires_in_days') || 7
    ends_on = Time.current + expires_in_days.days

    @account.custom_attributes ||= {}
    @account.custom_attributes.merge!({
                                        'plan_name' => trial_plan_name,
                                        'subscribed_quantity' => 1,
                                        'subscription_status' => 'active',
                                        'subscription_ends_on' => ends_on.iso8601
                                      })
  end

  def add_store_id_to_account
    store_id = generate_store_id
    @account.update!(
      custom_attributes: @account.custom_attributes.merge(store_id: store_id)
    )
    Rails.logger.info "Generated store_id: #{store_id} for account: #{@account.id}"
  end

  def generate_store_id
    padded_id = @account.id.to_s.rjust(12, '0')
    store_uuid = "00000000-0000-0000-0000-#{padded_id}"
    return store_uuid
  end
end

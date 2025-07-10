class ChatscommerceAccountBuilder
  include CustomExceptions::Account

  class BuildError < StandardError; end

  def self.perform(params)
    new(params).perform
  end

  def initialize(params)
    @email = params[:email]
    @password = params[:password]
    @account_name = params[:account_name]
    @user_full_name = params[:user_full_name]
    @locale = params[:locale] || I18n.locale
  end

  def perform
    ActiveRecord::Base.transaction do
      user, account = create_account
      setup_chatscommerce_store(account)
      { user: user, account: account }
    end
  rescue BuildError => e
    raise e
  rescue StandardError => e
    raise BuildError, "Account creation failed: #{e.message}"
  end

  private

  def create_account
    AccountBuilder.new(
      account_name: @account_name,
      email: @email,
      confirmed: true,
      user: nil,
      user_full_name: @user_full_name,
      user_password: @password,
      super_admin: false,
      locale: @locale
    ).perform
  end

  def setup_chatscommerce_store(account)
    ChatscommerceService::SetupService.setup_store(account, @email)
  rescue ChatscommerceService::SetupService::SetupError => e
    raise BuildError, "Store setup failed, #{e.message}"
  end
end
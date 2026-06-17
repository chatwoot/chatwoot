module Enterprise::Api::V2::AccountsController
  def create
    super
    record_marketing_attribution
  end

  private

  def record_marketing_attribution
    return if current_user.present?
    return if @account.blank?

    Internal::Accounts::MarketingAttributionService.new(account: @account, cookies: cookies).perform
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end

  def fetch_account_and_user_info
    @data = fetch_from_clearbit

    return if @data.blank?

    update_user_info
  end

  def fetch_from_clearbit
    Enterprise::ClearbitLookupService.lookup(@user.email)
  rescue StandardError => e
    Rails.logger.error "Error fetching data from clearbit: #{e}"
    nil
  end

  def update_user_info
    @user.update!(name: @data[:name]) if @data[:name].present?
  end

  def data_from_clearbit
    return {} if @data.blank?

    { name: @data[:company_name],
      custom_attributes: {
        'industry' => @data[:industry],
        'company_size' => @data[:company_size],
        'timezone' => @data[:timezone],
        'logo' => @data[:logo]
      } }
  end

  def account_attributes
    super.deep_merge(
      data_from_clearbit
    )
  end
end

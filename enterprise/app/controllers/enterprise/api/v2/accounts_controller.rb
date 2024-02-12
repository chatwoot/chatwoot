module Enterprise::Api::V2::AccountsController
  private

  def fetch_account_and_user_info
    data = fetch_from_clearbit

    return if data.blank?

    update_user_info(data)
    update_account_info(data)
  end

  def fetch_from_clearbit
    Enterprise::ClearbitLookupService.lookup(@user.email)
  rescue StandardError => e
    Rails.logger.error "Error fetching data from clearbit: #{e}"
    nil
  end

  def update_user_info(data)
    @user.update!(name: data[:name])
  end

  def update_account_info(data)
    @account.update!(
      name: data[:company_name],
      custom_attributes: @account.custom_attributes.merge(
        'industry' => data[:industry],
        'company_size' => data[:company_size],
        'timezone' => data[:timezone],
        'logo' => data[:logo]
      )
    )
  end
end

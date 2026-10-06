class SuperAdmin::SearchService
  RESULTS_LIMIT = 5

  pattr_initialize [:params!, :search_type!]

  def perform
    case search_type
    when 'Account'
      { accounts: filter_accounts }
    when 'User'
      { users: filter_users }
    end
  end

  private

  def search_query
    @search_query ||= params[:q].to_s.strip
  end

  def search_by_id?
    search_query.match?(/\A\d+\z/)
  end

  # One more than shown tells the bar whether a "see all" link is worth offering.
  def filter_accounts
    accounts = Account.order(id: :desc).limit(RESULTS_LIMIT + 1)
    return accounts.where(id: search_query) if search_by_id?

    accounts.where('name ILIKE :search', search: "%#{search_query}%")
  end

  def filter_users
    users = User.order(id: :desc).limit(RESULTS_LIMIT + 1)
    return users.where(id: search_query) if search_by_id?

    users.where('name ILIKE :search OR email ILIKE :search', search: "%#{search_query}%")
  end
end

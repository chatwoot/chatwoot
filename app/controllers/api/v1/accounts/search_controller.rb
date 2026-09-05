class Api::V1::Accounts::SearchController < Api::V1::Accounts::BaseController
  def index
    @result = search('all')
  end

  def conversations
    @result = search('Conversation')
  end

  def contacts
    raise Pundit::NotAuthorizedError if restricted_agent?

    @result = search('Contact')
  end

  def messages
    @result = search('Message')
  end

  def articles
    @result = search('Article')
  end

  private

  def restricted_agent?
    account_user = Current.account.account_users.find_by(user: Current.user)
    Conversations::AgentAccessService.restricted_agent?(account_user)
  end

  def search(search_type)
    SearchService.new(
      current_user: Current.user,
      current_account: Current.account,
      search_type: search_type,
      params: params
    ).perform
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

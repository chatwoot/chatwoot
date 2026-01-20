class Api::V1::Accounts::SearchController < Api::V1::Accounts::BaseController
  def index
    @result = search('all')
  end

  def conversations
    @result = search('Conversation')
  end

  def contacts
    @result = search('Contact')
  end

  def messages
    @search_service = build_search_service('Message')
    @result = @search_service.perform
  end

  private

  def search(search_type)
    build_search_service(search_type).perform
  end

  def build_search_service(search_type)
    SearchService.new(
      current_user: Current.user,
      current_account: Current.account,
      search_type: search_type,
      params: params
    )
  end
end

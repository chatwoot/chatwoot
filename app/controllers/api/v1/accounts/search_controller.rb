class Api::V1::Accounts::SearchController < Api::V1::Accounts::BaseController
  def index
    @result = text_search('all')
  end

  def conversations
    @result = text_search('Coversation')
  end

  def contacts
    @result = text_search('Contact')
  end

  def messages
    @result = text_search('Message')
  end

  private

  def text_search(search_type)
    TextSearch.new(
      current_user: Current.user,
      current_account: Current.account,
      search_type: search_type,
      params: params
    ).perform
  end
end

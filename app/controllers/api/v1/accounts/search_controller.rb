class Api::V1::Accounts::SearchController < Api::V1::Accounts::BaseController
  reads_from_replica :contacts, max_lag: 10.seconds
  reads_from_replica :conversations, max_lag: 10.seconds, access_context: true

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
    @result = search('Message')
  end

  def articles
    @result = search('Article')
  end

  private

  def search(search_type)
    SearchService.new(
      current_user: Current.user,
      current_account: Current.account,
      search_type: search_type,
      params: params,
      access_context: @read_replica_access_context
    ).perform
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

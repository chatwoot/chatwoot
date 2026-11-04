class SuperAdmin::SearchController < SuperAdmin::ApplicationController
  layout false
  before_action :validate_query

  def accounts
    @result = search('Account')
    render :index
  end

  def users
    @result = search('User')
    render :index
  end

  private

  def validate_query
    head :unprocessable_entity unless params[:q].is_a?(String)
  end

  def search(search_type)
    SuperAdmin::SearchService.new(search_type: search_type, params: params).perform
  end
end

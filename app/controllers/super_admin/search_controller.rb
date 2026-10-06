class SuperAdmin::SearchController < SuperAdmin::ApplicationController
  layout false

  def accounts
    @result = search('Account')
    render :index
  end

  def users
    @result = search('User')
    render :index
  end

  private

  def search(search_type)
    SuperAdmin::SearchService.new(search_type: search_type, params: params).perform
  end
end

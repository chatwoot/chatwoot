class Api::V1::Accounts::ResponseSourcesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization

  def parse
    links = PageCrawlerService.new(params[:link]).get_links
    render json: { links: links }
  end

  def create
    @response_source = Current.account.response_sources.new(response_source_params)
    @response_source.save!
    @response_source
  end

  private

  def response_source_params
    params.require(:response_source).permit(:name, :source_link, :inbox_id,
                                            response_documents_attributes: [:document_link])
  end
end

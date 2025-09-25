class Api::V1::AppleMessagesController < Api::V1::BaseController
  before_action :check_authorization

  def parse_url
    url = params[:url]
    
    if url.blank?
      render json: { error: 'URL is required' }, status: :bad_request
      return
    end

    begin
      parser_service = AppleMessagesForBusiness::OpenGraphParserService.new(url)
      result = parser_service.parse

      if result[:success]
        render json: {
          url: result[:url],
          title: result[:title],
          description: result[:description],
          image_url: result[:image_url],
          favicon_url: result[:favicon_url],
          site_name: result[:site_name]
        }
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "Apple Messages URL parsing failed: #{e.message}"
      render json: { error: 'Failed to parse URL' }, status: :internal_server_error
    end
  end

  private

  def check_authorization
    authorize! :read, current_account
  end
end
class Onehash::IntegrationController < ApplicationController
  include RequestExceptionHandler

  before_action :validate_request

  def validate_request
    api_key = request.headers['Authorization']&.split(' ')&.last
    return unless api_key != ENV['ONEHASH_API_KEY']

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end

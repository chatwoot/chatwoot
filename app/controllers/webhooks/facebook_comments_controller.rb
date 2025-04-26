class Webhooks::FacebookCommentsController < ActionController::API
  include MetaTokenVerifyConcern
  
  def verify
    if valid_token?(params['hub.verify_token'])
      Rails.logger.info("Facebook comment webhook verified")
      render json: params['hub.challenge']
    else
      Rails.logger.warn("Facebook comment webhook verification failed")
      render status: :unauthorized, json: { error: 'Error; wrong verify token' }
    end
  end
  
  def events
    Rails.logger.info("Facebook comment webhook received events")
    if params['object'] == 'page'
      # Xử lý webhook từ Facebook
      Webhooks::FacebookCommentsJob.perform_later(params.to_unsafe_hash)
      render json: :ok
    else
      Rails.logger.warn("Message is not received from the facebook webhook event: #{params['object']}")
      head :unprocessable_entity
    end
  end
  
  private
  
  def valid_token?(token)
    token == GlobalConfigService.load('FB_COMMENT_VERIFY_TOKEN', '')
  end
end

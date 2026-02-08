class Api::V1::Accounts::StickersController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  
  rescue_from StickerService::StickerError, with: :handle_sticker_service_error
  rescue_from GiphyService::GiphyError, with: :handle_giphy_service_error
  rescue_from Whatsapp::SendStickerService::StickerSendError, with: :handle_send_sticker_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

  # GET /api/v1/accounts/:account_id/stickers
  def index
    begin
      stickers = case params[:provider]
                 when 'giphy'
                   handle_giphy_request
                 when 'custom'
                   handle_custom_stickers_request
                 when 'recent'
                   handle_recent_stickers_request
                 else
                   { stickers: [], error: 'INVALID_PROVIDER', message: 'Invalid provider specified' }
                 end

      if stickers.is_a?(Hash) && stickers.key?(:error)
        render json: stickers, status: :unprocessable_entity
      else
        render json: { stickers: stickers }
      end
    rescue StandardError => e
      Rails.logger.error "StickersController index error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { 
        error: 'UNKNOWN_ERROR', 
        message: 'An unexpected error occurred. Please try again.',
        stickers: []
      }, status: :internal_server_error
    end
  end

  # GET /api/v1/accounts/:account_id/stickers/packs
  def packs
    packs = StickerService.new(current_account).custom_sticker_packs
    render json: { packs: packs }
  end

  # POST /api/v1/accounts/:account_id/stickers/send_sticker
  def send_sticker
    begin
      validate_send_sticker_params!
      
      conversation = current_account.conversations.find_by!(display_id: params[:conversation_id])
      
      # CRITICAL DEBUG: Log conversation details in controller
      Rails.logger.info "StickersController: Found conversation #{conversation.id}"
      Rails.logger.info "  - Account ID: #{conversation.account_id}"
      Rails.logger.info "  - Inbox ID: #{conversation.inbox_id}"
      Rails.logger.info "  - Contact ID: #{conversation.contact.id}"
      Rails.logger.info "  - Contact Name: #{conversation.contact.name}"
      Rails.logger.info "  - Contact Phone: #{conversation.contact.phone_number}"
      Rails.logger.info "  - ContactInbox ID: #{conversation.contact_inbox.id}"
      Rails.logger.info "  - ContactInbox Source ID: #{conversation.contact_inbox.source_id}"
      Rails.logger.info "  - Current Account ID: #{current_account.id}"
      Rails.logger.info "  - Requested Conversation ID: #{params[:conversation_id]}"
      Rails.logger.info "  - Conversation Status: #{conversation.status}"
      Rails.logger.info "  - Last Updated: #{conversation.updated_at}"
      
      # Check if this matches expected Witalo data
      witalo_phone = "558597550136"
      is_witalo = conversation.contact.phone_number&.include?(witalo_phone) || 
                  conversation.contact_inbox.source_id&.include?(witalo_phone)
      Rails.logger.info "  - Is Witalo's conversation: #{is_witalo}"
      Rails.logger.info "  - Expected Witalo phone: #{witalo_phone}"
      
      # Validate that this is a WhatsApp conversation
      unless conversation.inbox.channel_type == 'Channel::Whatsapp'
        return render json: { 
          error: 'INVALID_CHANNEL_TYPE',
          message: 'Stickers are only supported for WhatsApp conversations',
          user_message: 'Stickers can only be sent in WhatsApp conversations.'
        }, status: :unprocessable_entity
      end

      Rails.logger.info "StickersController: About to call SendStickerService for conversation #{conversation.id}"
      Rails.logger.info "StickersController: Sticker params: #{sticker_params.to_h}"
      
      result = Whatsapp::SendStickerService.new(
        conversation: conversation,
        sticker_data: sticker_params.to_h.symbolize_keys,
        user: current_user
      ).perform
      
      Rails.logger.info "StickersController: SendStickerService result: #{result}"

      if result[:success]
        render json: { success: true, message_id: result[:message_id] }
      else
        render json: {
          success: false,
          error: result[:error],
          error_code: result[:error_code],
          user_message: result[:user_message]
        }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: {
        error: 'CONVERSATION_NOT_FOUND',
        message: 'Conversation not found',
        user_message: 'Conversation not found. Please refresh the page and try again.'
      }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "StickersController send_sticker error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: {
        error: 'UNKNOWN_ERROR',
        message: 'An unexpected error occurred',
        user_message: 'Unable to send sticker. Please try again.'
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/accounts/:account_id/stickers/upload
  def upload
    begin
      validate_upload_params!
      
      result = StickerService.new(current_account).create_custom_sticker(
        upload_params[:pack_name],
        upload_params[:file],
        upload_params[:tags] || []
      )

      if result[:success]
        render json: { success: true, sticker: result[:sticker] }
      else
        render json: {
          success: false,
          errors: result[:errors],
          error_code: result[:error_code],
          user_message: result[:user_message]
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "StickersController upload error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: {
        success: false,
        error: 'UPLOAD_ERROR',
        message: 'Failed to upload sticker',
        user_message: 'Failed to upload sticker. Please try again.'
      }, status: :internal_server_error
    end
  end

  # DELETE /api/v1/accounts/:account_id/stickers/:id
  def destroy
    result = StickerService.new(current_account).delete_custom_sticker(params[:id])

    if result[:success]
      render json: { success: true }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/stickers/:id/pack
  def update_pack
    result = StickerService.new(current_account).update_sticker_pack(
      params[:id],
      params[:pack_name]
    )

    if result[:success]
      render json: { success: true }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def handle_giphy_request
    # Temporary test response to debug the issue
    Rails.logger.info "StickersController: Handling Giphy request with search_term: #{params[:search_term]}"
    
    begin
      result = GiphyService.new.search_or_trending(params[:search_term])
      Rails.logger.info "StickersController: GiphyService result: #{result.inspect}"
      
      if result.is_a?(Hash) && result.key?(:error)
        Rails.logger.warn "StickersController: GiphyService returned error: #{result[:error]}"
        result
      else
        Rails.logger.info "StickersController: GiphyService returned #{result.is_a?(Array) ? result.length : 'non-array'} stickers"
        result
      end
    rescue StandardError => e
      Rails.logger.error "StickersController: Exception in handle_giphy_request: #{e.message}\n#{e.backtrace.join("\n")}"
      { error: 'GIPHY_SERVICE_ERROR', message: e.message, stickers: [] }
    end
  end

  def handle_custom_stickers_request
    StickerService.new(current_account).custom_stickers(params[:pack_name])
  rescue StickerService::StickerError => e
    { stickers: [], error: 'CUSTOM_STICKERS_ERROR', message: e.message }
  end

  def handle_recent_stickers_request
    recent_stickers_for_user
  rescue StandardError => e
    Rails.logger.error "Error fetching recent stickers: #{e.message}"
    []
  end

  def recent_stickers_for_user
    recent_stickers = current_user.ui_settings&.dig('recent_stickers') || []
    recent_stickers.map do |sticker_data|
      {
        id: sticker_data['id'] || sticker_data['url'],
        url: sticker_data['url'],
        alt: sticker_data['alt'] || 'Recent Sticker',
        provider: sticker_data['provider'] || 'unknown',
        used_at: sticker_data['used_at']
      }
    end
  end

  def validate_send_sticker_params!
    unless params[:conversation_id].present?
      raise ArgumentError, 'Conversation ID is required'
    end
    
    unless params[:sticker].present?
      raise ArgumentError, 'Sticker data is required'
    end
    
    sticker_data = sticker_params.to_h
    unless sticker_data[:url].present?
      raise ArgumentError, 'Sticker URL is required'
    end
  end

  def validate_upload_params!
    unless params[:file].present?
      raise ArgumentError, 'File is required'
    end
    
    unless params[:pack_name].present?
      raise ArgumentError, 'Pack name is required'
    end
    
    # Validate file size (basic check before processing)
    if params[:file].respond_to?(:size) && params[:file].size > 5.megabytes
      raise ArgumentError, 'File too large (max 5MB)'
    end
  end

  def handle_sticker_service_error(error)
    Rails.logger.error "StickerService error: #{error.message}"
    
    error_response = case error
                     when StickerService::ValidationError
                       { error: 'VALIDATION_ERROR', message: error.message, user_message: 'Invalid input. Please check your data and try again.' }
                     when StickerService::StickerNotFoundError
                       { error: 'STICKER_NOT_FOUND', message: error.message, user_message: 'Sticker not found.' }
                     when StickerService::StorageError
                       { error: 'STORAGE_ERROR', message: error.message, user_message: 'Failed to save sticker. Please try again.' }
                     else
                       { error: 'STICKER_SERVICE_ERROR', message: error.message, user_message: 'An error occurred. Please try again.' }
                     end
    
    render json: error_response, status: :unprocessable_entity
  end

  def handle_giphy_service_error(error)
    Rails.logger.error "GiphyService error: #{error.message}"
    
    error_response = case error
                     when GiphyService::ApiKeyMissingError
                       { error: 'GIPHY_CONFIG_ERROR', message: error.message, user_message: 'Giphy integration not available.' }
                     when GiphyService::RateLimitError
                       { error: 'GIPHY_RATE_LIMIT', message: error.message, user_message: 'Too many requests. Please try again later.' }
                     when GiphyService::ApiUnavailableError
                       { error: 'GIPHY_UNAVAILABLE', message: error.message, user_message: 'Giphy service temporarily unavailable.' }
                     else
                       { error: 'GIPHY_ERROR', message: error.message, user_message: 'Unable to load stickers. Please try again.' }
                     end
    
    render json: error_response, status: :service_unavailable
  end

  def handle_send_sticker_error(error)
    Rails.logger.error "SendStickerService error: #{error.message}"
    
    error_response = case error
                     when Whatsapp::SendStickerService::InvalidStickerDataError
                       { error: 'INVALID_STICKER', message: error.message, user_message: 'Invalid sticker data.' }
                     when Whatsapp::SendStickerService::MediaUploadError
                       { error: 'MEDIA_UPLOAD_FAILED', message: error.message, user_message: 'Failed to upload sticker.' }
                     when Whatsapp::SendStickerService::WhatsAppApiError
                       { error: 'WHATSAPP_ERROR', message: error.message, user_message: 'WhatsApp service error.' }
                     else
                       { error: 'SEND_STICKER_ERROR', message: error.message, user_message: 'Failed to send sticker.' }
                     end
    
    render json: error_response, status: :unprocessable_entity
  end

  def handle_record_not_found(error)
    Rails.logger.error "Record not found: #{error.message}"
    render json: {
      error: 'RECORD_NOT_FOUND',
      message: 'Record not found',
      user_message: 'The requested item was not found.'
    }, status: :not_found
  end

  def sticker_params
    params.require(:sticker).permit(:url, :alt, :provider, :id)
  end

  def upload_params
    params.permit(:file, :pack_name, tags: [])
  end

  def check_authorization
    # Use Sticker model for authorization
    case action_name
    when 'upload'
      authorize Sticker, :create?
    else
      authorize Sticker
    end
  end
end
# frozen_string_literal: true

class AppleMessagesForBusiness::AttachmentsController < ApplicationController
  # Skip authentication for ngrok bypass - we'll handle security differently
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user
  before_action :set_attachment
  before_action :verify_access_token, only: [:show, :download]

  def show
    # Stream the file directly to bypass ngrok warning page
    if @attachment.file.attached?
      # Set headers to bypass ngrok browser warning and improve browser compatibility
      response.headers['ngrok-skip-browser-warning'] = 'true'
      response.headers['User-Agent'] = 'Chatwoot-Apple-Messages-For-Business'
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'GET, HEAD, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept'
      response.headers['Cache-Control'] = 'public, max-age=3600'
      
      # Additional headers for browser compatibility
      response.headers['X-Content-Type-Options'] = 'nosniff'
      response.headers['Cross-Origin-Resource-Policy'] = 'cross-origin'
      
      # Critical: Add headers to prevent ngrok browser warning when accessed from frontend
      response.headers['X-Frame-Options'] = 'SAMEORIGIN'
      response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
      
      # Handle HEAD requests properly
      if request.head?
        response.headers['Content-Type'] = @attachment.file.content_type
        response.headers['Content-Length'] = @attachment.file.byte_size.to_s
        response.headers['Content-Disposition'] = "inline; filename=\"#{@attachment.file.filename}\""
        head :ok
      else
        # For browser requests, ensure proper content serving
        send_data @attachment.file.download,
                  filename: @attachment.file.filename.to_s,
                  type: @attachment.file.content_type,
                  disposition: 'inline'
      end
    else
      head :not_found
    end
  end

  def download
    # Stream the file directly to bypass ngrok warning
    if @attachment.file.attached?
      # Set headers to bypass ngrok browser warning
      response.headers['ngrok-skip-browser-warning'] = 'true'
      response.headers['User-Agent'] = 'Chatwoot-Apple-Messages-For-Business'
      
      send_data @attachment.file.download,
                filename: @attachment.file.filename.to_s,
                type: @attachment.file.content_type,
                disposition: 'attachment'
    else
      head :not_found
    end
  end

  private

  def set_attachment
    @attachment = Attachment.find(params[:id])
    
    # Ensure this attachment belongs to an Apple Messages for Business channel
    unless @attachment.message&.inbox&.channel_type == 'Channel::AppleMessagesForBusiness'
      head :forbidden
      return
    end
  end

  def verify_access_token
    # Use a simple token-based authentication for ngrok bypass
    token = params[:token] || request.headers['X-Access-Token']
    expected_token = generate_attachment_token(@attachment.id)
    
    unless token == expected_token
      head :forbidden
    end
  end

  def generate_attachment_token(attachment_id)
    # Generate a simple token based on attachment ID and a secret
    secret = Rails.application.secret_key_base
    Digest::SHA256.hexdigest("#{attachment_id}-#{secret}")[0..15]
  end
end
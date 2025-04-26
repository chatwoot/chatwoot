class Api::V1::Accounts::FacebookCommentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  
  def reply
    # Xác thực thông tin
    unless valid_params?
      render json: { error: 'Invalid parameters' }, status: :unprocessable_entity
      return
    end
    
    # Tìm Facebook Page
    channel = Current.account.facebook_pages.find_by(page_id: params[:page_id])
    unless channel
      render json: { error: 'Facebook page not found' }, status: :not_found
      return
    end
    
    # Gửi phản hồi đến comment
    result = Facebook::CommentService.new(
      channel: channel,
      comment_id: params[:comment_id],
      content: params[:content]
    ).reply
    
    if result[:success]
      render json: { success: true, data: result[:data] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end
  
  def send_message
    # Xác thực thông tin
    unless valid_message_params?
      render json: { error: 'Invalid parameters' }, status: :unprocessable_entity
      return
    end
    
    # Tìm Facebook Page
    channel = Current.account.facebook_pages.find_by(page_id: params[:page_id])
    unless channel
      render json: { error: 'Facebook page not found' }, status: :not_found
      return
    end
    
    # Gửi tin nhắn trực tiếp
    result = Facebook::DirectMessageService.new(
      channel: channel,
      user_id: params[:user_id],
      content: params[:content]
    ).send
    
    if result[:success]
      render json: { success: true, data: result[:data] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end
  
  def configure
    # Xác thực thông tin
    unless valid_config_params?
      render json: { error: 'Invalid parameters' }, status: :unprocessable_entity
      return
    end
    
    # Tìm inbox
    inbox = Current.account.inboxes.find_by(id: params[:inbox_id])
    unless inbox && inbox.channel_type == 'Channel::FacebookPage'
      render json: { error: 'Facebook inbox not found' }, status: :not_found
      return
    end
    
    # Tạo hoặc cập nhật cấu hình webhook
    config = FacebookCommentConfig.find_or_initialize_by(
      account_id: Current.account.id,
      inbox_id: inbox.id
    )
    
    config.webhook_url = params[:webhook_url]
    config.status = params[:status] || 'active'
    
    # Tạo webhook_secret nếu chưa có
    if config.new_record? || params[:regenerate_secret]
      config.additional_attributes = config.additional_attributes.merge(
        'webhook_secret' => SecureRandom.hex(16)
      )
    end
    
    if config.save
      render json: {
        id: config.id,
        account_id: config.account_id,
        inbox_id: config.inbox_id,
        webhook_url: config.webhook_url,
        status: config.status,
        webhook_secret: config.additional_attributes['webhook_secret'],
        created_at: config.created_at,
        updated_at: config.updated_at
      }
    else
      render json: { errors: config.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def show
    inbox = Current.account.inboxes.find_by(id: params[:inbox_id])
    unless inbox && inbox.channel_type == 'Channel::FacebookPage'
      render json: { error: 'Facebook inbox not found' }, status: :not_found
      return
    end
    
    config = FacebookCommentConfig.find_by(
      account_id: Current.account.id,
      inbox_id: inbox.id
    )
    
    if config
      render json: {
        id: config.id,
        account_id: config.account_id,
        inbox_id: config.inbox_id,
        webhook_url: config.webhook_url,
        status: config.status,
        webhook_secret: config.additional_attributes['webhook_secret'],
        created_at: config.created_at,
        updated_at: config.updated_at
      }
    else
      render json: { error: 'Configuration not found' }, status: :not_found
    end
  end
  
  private
  
  def valid_params?
    params[:comment_id].present? && params[:page_id].present? && params[:content].present?
  end
  
  def valid_message_params?
    params[:user_id].present? && params[:page_id].present? && params[:content].present?
  end
  
  def valid_config_params?
    params[:inbox_id].present? && params[:webhook_url].present?
  end
  
  def check_authorization
    authorize ::Account
  end
end

class Api::V1::Accounts::CallbacksController < Api::V1::Accounts::BaseController
  before_action :inbox, only: [:reauthorize_page]

  def register_facebook_page
    user_access_token = params[:user_access_token]
    page_access_token = params[:page_access_token]
    page_id = params[:page_id]
    inbox_name = params[:inbox_name]
    ActiveRecord::Base.transaction do
      facebook_channel = Current.account.facebook_pages.create!(
        page_id: page_id, user_access_token: user_access_token,
        page_access_token: page_access_token
      )
      @facebook_inbox = Current.account.inboxes.create!(name: inbox_name, channel: facebook_channel)
      set_instagram_id(page_access_token, facebook_channel)
      set_avatar(@facebook_inbox, page_id)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    Rails.logger.error "Error in register_facebook_page: #{e.message}"
    # Additional log statements
    log_additional_info
  end

  def log_additional_info
    Rails.logger.debug do
      "user_access_token: #{params[:user_access_token]} , page_access_token: #{params[:page_access_token]} ,
      page_id: #{params[:page_id]}, inbox_name: #{params[:inbox_name]}"
    end
  end

  def facebook_pages
    @page_details = mark_already_existing_facebook_pages(fb_object.get_connections('me', 'accounts'))
  end

  def set_instagram_id(page_access_token, facebook_channel)
    fb_object = Koala::Facebook::API.new(page_access_token)
    response = fb_object.get_connections('me', '', { fields: 'instagram_business_account' })
    return if response['instagram_business_account'].blank?

    instagram_id = response['instagram_business_account']['id']
    facebook_channel.update(instagram_id: instagram_id)
  rescue StandardError => e
    Rails.logger.error "Error in set_instagram_id: #{e.message}"
  end

  # get params[:inbox_id], current_account. params[:omniauth_token]
  def reauthorize_page
    if @inbox&.facebook?
      fb_page_id = @inbox.channel.page_id
      page_details = fb_object.get_connections('me', 'accounts')

      if (page_detail = (page_details || []).detect { |page| fb_page_id == page['id'] })
        update_fb_page(fb_page_id, page_detail['access_token'])
        render and return
      end
    end

    head :unprocessable_entity
  end

  private

  def inbox
    @inbox = Current.account.inboxes.find_by(id: params[:inbox_id])
  end

  def update_fb_page(fb_page_id, access_token)
    fb_page = get_fb_page(fb_page_id)
    ActiveRecord::Base.transaction do
      fb_page&.update!(user_access_token: @user_access_token, page_access_token: access_token)
      set_instagram_id(access_token, fb_page)
      fb_page&.reauthorized!
    rescue StandardError => e
      ChatwootExceptionTracker.new(e).capture_exception
      Rails.logger.error "Error in update_fb_page: #{e.message}"
    end
  end

  def get_fb_page(fb_page_id)
    Current.account.facebook_pages.find_by(page_id: fb_page_id)
  end

  def fb_object
    @user_access_token = long_lived_token(params[:omniauth_token])
    Koala::Facebook::API.new(@user_access_token)
  end

  def long_lived_token(omniauth_token)
    koala = Koala::Facebook::OAuth.new(GlobalConfigService.load('FB_APP_ID', ''), GlobalConfigService.load('FB_APP_SECRET', ''))
    koala.exchange_access_token_info(omniauth_token)['access_token']
  rescue StandardError => e
    Rails.logger.error "Error in long_lived_token: #{e.message}"
  end

  def mark_already_existing_facebook_pages(data)
    return [] if data.empty?

    data.inject([]) do |result, page_detail|
      page_detail[:exists] = Current.account.facebook_pages.exists?(page_id: page_detail['id'])
      result << page_detail
    end
  end

  def set_avatar(facebook_inbox, page_id)
    avatar_url = "https://graph.facebook.com/#{page_id}/picture?type=large"
    Avatar::AvatarFromUrlJob.perform_later(facebook_inbox, avatar_url)
  end

  # API endpoint để kiểm tra trạng thái token Facebook
  def check_facebook_token_status
    inbox = Current.account.inboxes.find(params[:inbox_id])

    unless inbox.facebook?
      render json: { error: 'Not a Facebook inbox' }, status: :unprocessable_entity
      return
    end

    refresh_service = Facebook::RefreshOauthTokenService.new(channel: inbox.channel)

    render json: {
      inbox_id: inbox.id,
      page_id: inbox.channel.page_id,
      token_valid: refresh_service.token_valid?,
      reauthorization_required: inbox.channel.reauthorization_required?,
      last_checked: Time.current.iso8601
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  # API endpoint để trigger refresh token Facebook
  def refresh_facebook_token
    inbox = Current.account.inboxes.find(params[:inbox_id])

    unless inbox.facebook?
      render json: { error: 'Not a Facebook inbox' }, status: :unprocessable_entity
      return
    end

    refresh_service = Facebook::RefreshOauthTokenService.new(channel: inbox.channel)

    # Kiểm tra token hiện tại
    was_valid_before = refresh_service.token_valid?

    # Thử refresh
    result = refresh_service.attempt_token_refresh

    # Kiểm tra lại sau refresh
    is_valid_after = refresh_service.token_valid?

    if is_valid_after
      render json: {
        success: true,
        message: was_valid_before ? 'Token was already valid' : 'Token successfully refreshed',
        inbox_id: inbox.id,
        page_id: inbox.channel.page_id,
        token_valid: true,
        reauthorization_required: inbox.channel.reauthorization_required?
      }
    else
      render json: {
        success: false,
        message: 'Token refresh failed - manual reauthorization required',
        inbox_id: inbox.id,
        page_id: inbox.channel.page_id,
        token_valid: false,
        reauthorization_required: inbox.channel.reauthorization_required?
      }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end
end

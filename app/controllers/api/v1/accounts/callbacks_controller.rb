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
    rescue StandardError => e
      ChatwootExceptionTracker.new(e).capture_exception
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
    Rails.logger.error e
  end

  def mark_already_existing_facebook_pages(data)
    return [] if data.empty?

    data.inject([]) do |result, page_detail|
      page_detail[:exists] = Current.account.facebook_pages.exists?(page_id: page_detail['id'])
      result << page_detail
    end
  end

  def set_avatar(facebook_inbox, page_id)
    avatar_file = Down.download(
      "http://graph.facebook.com/#{page_id}/picture?type=large"
    )
    facebook_inbox.avatar.attach(io: avatar_file, filename: avatar_file.original_filename, content_type: avatar_file.content_type)
  end
end

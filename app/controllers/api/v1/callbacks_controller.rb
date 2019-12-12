require 'rest-client'
require 'telegram/bot'
class Api::V1::CallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:register_facebook_page]
  skip_before_action :authenticate_user!, only: [:register_facebook_page], raise: false

  def register_facebook_page
    user_access_token = params[:user_access_token]
    page_access_token = params[:page_access_token]
    page_name = params[:page_name]
    page_id = params[:page_id]
    inbox_name = params[:inbox_name]
    facebook_channel = current_account.facebook_pages.create!(
      name: page_name, page_id: page_id, user_access_token: user_access_token,
      page_access_token: page_access_token, remote_avatar_url: set_avatar(page_id)
    )
    inbox = current_account.inboxes.create!(name: inbox_name, channel: facebook_channel)
    render json: inbox
  end

  def get_facebook_pages
    @page_details = mark_already_existing_facebook_pages(fb_object.get_connections('me', 'accounts'))
  end

  # get params[:inbox_id], current_account, params[:omniauth_token]
  def reauthorize_page
    if @inbox&.first&.facebook?
      fb_page_id = @inbox.channel.page_id
      page_details = fb_object.get_connections('me', 'accounts')

      (page_details || []).each do |page_detail|
        if fb_page_id == page_detail['id'] # found the page which has to be reauthorised
          update_fb_page(fb_page_id, page_detail['access_token'])
          head :ok
        end
      end
    end

    head :unprocessable_entity
  end

  private

  def inbox
    @inbox = current_account.inboxes.find_by(id: params[:inbox_id])
  end

  def update_fb_page
    if fb_page(fb_page_id)
      fb_page.update_attributes!(
        user_access_token: @user_access_token, page_access_token: access_token
      )
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def fb_page(fb_page_id)
    current_account.facebook_pages.find_by(page_id: fb_page_id)
  end

  def fb_object
    @user_access_token = long_lived_token(params[:omniauth_token])
    Koala::Facebook::API.new(@user_access_token)
  end

  def long_lived_token(omniauth_token)
    koala = Koala::Facebook::OAuth.new(ENV['FB_APP_ID'], ENV['FB_APP_SECRET'])
    long_lived_token = koala.exchange_access_token_info(omniauth_token)['access_token']
  end

  def mark_already_existing_facebook_pages(data)
    return [] if data.empty?

    data.inject([]) do |result, page_detail|
      current_account.facebook_pages.exists?(page_id: page_detail['id']) ? page_detail.merge!(exists: true) : page_detail.merge!(exists: false)
      result << page_detail
    end
  end

  def set_avatar(page_id)
    begin
      url = 'http://graph.facebook.com/' << page_id << '/picture?type=large'
      uri = URI.parse(url)
      tries = 3
      begin
        response = uri.open(redirect: false)
      rescue OpenURI::HTTPRedirect => e
        uri = e.uri # assigned from the "Location" response header
        retry if (tries -= 1) > 0
        raise
      end
      pic_url = response.base_uri.to_s
      Rails.logger.info(pic_url)
    rescue StandardError => e
      pic_url = nil
    end
    pic_url
  end
end

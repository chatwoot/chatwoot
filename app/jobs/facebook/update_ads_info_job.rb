# frozen_string_literal: true

class Facebook::UpdateAdsInfoJob < ApplicationJob
  queue_as :low_priority
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(facebook_tracking_id)
    @facebook_tracking = FacebookAdsTracking.find_by(id: facebook_tracking_id)
    return unless @facebook_tracking

    Rails.logger.info("Updating ads info for tracking ID: #{facebook_tracking_id}")

    # Lấy access token từ inbox channel
    access_token = get_access_token
    return unless access_token

    # Khởi tạo service để lấy thông tin ads
    ads_service = Facebook::AdsInfoService.new(access_token: access_token)

    # Lấy thông tin tổng hợp
    ads_info = ads_service.get_comprehensive_ads_info(@facebook_tracking)

    # Cập nhật thông tin vào database
    update_tracking_with_ads_info(ads_info)

    Rails.logger.info("Successfully updated ads info for tracking ID: #{facebook_tracking_id}")
  rescue StandardError => e
    Rails.logger.error("Error updating ads info for tracking ID #{facebook_tracking_id}: #{e.message}")
    ChatwootExceptionTracker.new(e, account: @facebook_tracking&.account).capture_exception
    raise e
  end

  private

  def get_access_token
    # Lấy access token từ channel
    channel = @facebook_tracking.inbox.channel
    
    if channel.respond_to?(:access_token) && channel.access_token.present?
      channel.access_token
    else
      Rails.logger.error("No access token available for inbox #{@facebook_tracking.inbox.id}")
      nil
    end
  end

  def update_tracking_with_ads_info(ads_info)
    update_data = {}

    # Cập nhật thông tin ad
    if ads_info[:ad_info].present?
      ad_info = ads_info[:ad_info]
      update_data[:ad_title] = ad_info[:name] if ad_info[:name].present?
      
      # Cập nhật creative info
      if ad_info[:creative].present?
        creative = ad_info[:creative]
        update_data[:ad_title] ||= creative[:title] if creative[:title].present?
        update_data[:ad_photo_url] = creative[:image_url] if creative[:image_url].present?
        update_data[:ad_video_url] = creative[:video_id] if creative[:video_id].present?
      end
    end

    # Cập nhật campaign_id và adset_id nếu chưa có
    if ads_info[:ad_info].present?
      ad_info = ads_info[:ad_info]
      update_data[:campaign_id] ||= ad_info[:campaign_id] if ad_info[:campaign_id].present?
      update_data[:adset_id] ||= ad_info[:adset_id] if ad_info[:adset_id].present?
    end

    # Lưu thông tin chi tiết vào additional_attributes
    additional_attrs = @facebook_tracking.additional_attributes || {}
    additional_attrs[:ads_api_info] = {
      ad_info: ads_info[:ad_info],
      campaign_info: ads_info[:campaign_info],
      adset_info: ads_info[:adset_info],
      performance_metrics: ads_info[:performance_metrics],
      updated_at: Time.current.iso8601
    }
    update_data[:additional_attributes] = additional_attrs

    # Cập nhật database
    @facebook_tracking.update!(update_data)
  end
end

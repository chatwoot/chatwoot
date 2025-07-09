# frozen_string_literal: true

class FacebookAdsTracking < ApplicationRecord
  belongs_to :conversation
  belongs_to :message, optional: true
  belongs_to :contact
  belongs_to :inbox
  belongs_to :account

  validates :ref_parameter, presence: true
  validates :referral_source, presence: true
  validates :referral_type, presence: true

  # Store additional attributes as JSON
  store :additional_attributes, accessors: [:custom_events], coder: JSON

  scope :with_conversions_sent, -> { where(conversion_sent: true) }
  scope :pending_conversions, -> { where(conversion_sent: false) }
  scope :by_ad_id, ->(ad_id) { where(ad_id: ad_id) }
  scope :by_campaign_id, ->(campaign_id) { where(campaign_id: campaign_id) }
  scope :by_ref_parameter, ->(ref) { where(ref_parameter: ref) }
  scope :recent, -> { order(created_at: :desc) }

  # Extract campaign and adset IDs from ads context data
  def extract_campaign_and_adset_ids
    return unless raw_referral_data.present?

    Rails.logger.info("Extracting campaign and adset IDs from referral data: #{raw_referral_data}")

    # Facebook API v22+ có thể cung cấp trực tiếp campaign_id và adset_id
    # Ưu tiên lấy từ root level trước, sau đó từ ads_context_data
    self.campaign_id ||= extract_id_value(raw_referral_data['campaign_id'])
    self.adset_id ||= extract_id_value(raw_referral_data['adset_id'])

    # Fallback: lấy từ ads_context_data
    if campaign_id.blank? || adset_id.blank?
      ads_context = raw_referral_data['ads_context_data'] || {}
      self.campaign_id ||= extract_id_value(ads_context['campaign_id'])
      self.adset_id ||= extract_id_value(ads_context['adset_id'])
    end

    # Fallback: lấy từ referral object (Facebook Messenger format)
    if campaign_id.blank? || adset_id.blank?
      referral_obj = raw_referral_data['referral'] || {}
      self.campaign_id ||= extract_id_value(referral_obj['campaign_id'])
      self.adset_id ||= extract_id_value(referral_obj['adset_id'])
    end

    # Fallback cuối: thử extract từ ad_title hoặc các trường khác
    if campaign_id.blank? || adset_id.blank?
      ads_context = raw_referral_data['ads_context_data'] || {}
      self.campaign_id ||= extract_id_from_url(ads_context['ad_title'], 'campaign')
      self.adset_id ||= extract_id_from_url(ads_context['ad_title'], 'adset')
    end

    Rails.logger.info("Extracted IDs - Campaign: #{campaign_id}, Adset: #{adset_id}")
  end

  # Mark conversion as sent
  def mark_conversion_sent!(response = nil)
    update!(
      conversion_sent: true,
      conversion_sent_at: Time.current,
      conversion_response: response
    )
  end

  # Get conversion event data for Facebook/Instagram Conversions API
  def conversion_event_data
    {
      event_name: event_name || 'Lead',
      event_time: created_at.to_i,
      action_source: 'chat',
      user_data: {
        external_id: contact.id.to_s,
        client_ip_address: nil, # We don't have IP from messenger/instagram
        client_user_agent: nil, # We don't have user agent from messenger/instagram
        fb_login_id: contact.get_source_id(inbox.id)
      },
      custom_data: {
        content_name: ad_title,
        content_category: 'messaging',
        value: event_value || 0,
        currency: currency || 'USD',
        content_ids: [ad_id].compact,
        contents: [
          {
            id: ad_id,
            quantity: 1,
            item_price: event_value || 0
          }
        ].compact
      },
      event_source_url: build_event_source_url,
      opt_out: false
    }.compact
  end

  # Build appropriate source URL based on channel type
  def build_event_source_url
    if inbox.instagram?
      # Instagram DM link
      "https://www.instagram.com/direct/t/#{contact.get_source_id(inbox.id)}?ref=#{ref_parameter}"
    else
      # Facebook Messenger link
      "https://m.me/#{inbox.channel.page_id}?ref=#{ref_parameter}"
    end
  end

  # Check if this tracking is from Instagram
  def instagram_tracking?
    inbox.instagram?
  end

  # Check if this tracking is from Facebook
  def facebook_tracking?
    inbox.facebook?
  end

  # Get summary data for UI display
  def summary_data
    base_data = {
      id: id,
      ref_parameter: ref_parameter,
      referral_source: referral_source,
      referral_type: referral_type,
      ad_id: ad_id,
      campaign_id: campaign_id,
      adset_id: adset_id,
      ad_title: ad_title,
      ad_photo_url: ad_photo_url,
      ad_video_url: ad_video_url,
      event_name: event_name,
      event_value: event_value,
      currency: currency,
      conversion_sent: conversion_sent,
      conversion_sent_at: conversion_sent_at,
      created_at: created_at,
      conversation_id: conversation_id,
      contact_name: contact.name,
      contact_email: contact.email,
      contact_phone: contact.phone_number,
      inbox_type: inbox.channel_type,
      platform: instagram_tracking? ? 'Instagram' : 'Facebook'
    }

    # Thêm thông tin chi tiết từ Facebook API nếu có
    if additional_attributes&.dig('ads_api_info').present?
      api_info = additional_attributes['ads_api_info']
      base_data.merge!(
        api_info: {
          ad_info: api_info['ad_info'],
          campaign_info: api_info['campaign_info'],
          adset_info: api_info['adset_info'],
          performance_metrics: api_info['performance_metrics'],
          last_updated: api_info['updated_at']
        }
      )
    end

    base_data
  end

  private

  def extract_id_value(value)
    return nil if value.blank?

    # Nếu là string, thử convert sang integer nếu có thể
    if value.is_a?(String)
      # Loại bỏ các ký tự không phải số
      cleaned_value = value.gsub(/[^\d]/, '')
      return cleaned_value.present? ? cleaned_value : value
    end

    value.to_s
  end

  def extract_id_from_url(text, type)
    return nil unless text.present?

    # Try to extract IDs from text that might contain URLs or structured data
    case type
    when 'campaign'
      text.match(/campaign[_\-]?id[=:](\d+)/i)&.captures&.first
    when 'adset'
      text.match(/adset[_\-]?id[=:](\d+)/i)&.captures&.first
    end
  end
end

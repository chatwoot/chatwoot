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

    # Facebook ads context data might contain campaign and adset info
    ads_context = raw_referral_data['ads_context_data'] || {}

    # Try to extract from various possible fields
    self.campaign_id ||= ads_context['campaign_id'] || extract_id_from_url(ads_context['ad_title'], 'campaign')
    self.adset_id ||= ads_context['adset_id'] || extract_id_from_url(ads_context['ad_title'], 'adset')
  end

  # Mark conversion as sent
  def mark_conversion_sent!(response = nil)
    update!(
      conversion_sent: true,
      conversion_sent_at: Time.current,
      conversion_response: response
    )
  end

  # Get conversion event data for Facebook Conversions API
  def conversion_event_data
    {
      event_name: event_name || 'Lead',
      event_time: created_at.to_i,
      action_source: 'chat',
      user_data: {
        external_id: contact.id.to_s,
        client_ip_address: nil, # We don't have IP from messenger
        client_user_agent: nil, # We don't have user agent from messenger
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
      event_source_url: "https://m.me/#{inbox.channel.page_id}?ref=#{ref_parameter}",
      opt_out: false
    }.compact
  end

  # Get summary data for UI display
  def summary_data
    {
      id: id,
      ref_parameter: ref_parameter,
      referral_source: referral_source,
      referral_type: referral_type,
      ad_id: ad_id,
      campaign_id: campaign_id,
      adset_id: adset_id,
      ad_title: ad_title,
      event_name: event_name,
      event_value: event_value,
      currency: currency,
      conversion_sent: conversion_sent,
      conversion_sent_at: conversion_sent_at,
      created_at: created_at,
      conversation_id: conversation_id,
      contact_name: contact.name,
      contact_email: contact.email,
      contact_phone: contact.phone_number
    }
  end

  private

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

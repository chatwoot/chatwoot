# frozen_string_literal: true

class Facebook::AdsInfoService
  include HTTParty
  base_uri 'https://graph.facebook.com'

  def initialize(access_token:, api_version: 'v22.0')
    @access_token = access_token
    @api_version = api_version
  end

  # Lấy thông tin chi tiết về ad
  def get_ad_info(ad_id)
    return {} unless ad_id.present?

    begin
      response = self.class.get(
        "/#{@api_version}/#{ad_id}",
        query: {
          access_token: @access_token,
          fields: 'id,name,status,campaign_id,adset_id,creative{title,body,image_url,video_id},insights{impressions,clicks,cpm,cpc,ctr,spend}'
        }
      )

      if response.success?
        parse_ad_response(response.parsed_response)
      else
        Rails.logger.error("Facebook Ads API error for ad #{ad_id}: #{response.body}")
        {}
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching ad info for #{ad_id}: #{e.message}")
      {}
    end
  end

  # Lấy thông tin chi tiết về campaign
  def get_campaign_info(campaign_id)
    return {} unless campaign_id.present?

    begin
      response = self.class.get(
        "/#{@api_version}/#{campaign_id}",
        query: {
          access_token: @access_token,
          fields: 'id,name,status,objective,insights{impressions,clicks,spend,cpm,cpc,ctr}'
        }
      )

      if response.success?
        parse_campaign_response(response.parsed_response)
      else
        Rails.logger.error("Facebook Ads API error for campaign #{campaign_id}: #{response.body}")
        {}
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching campaign info for #{campaign_id}: #{e.message}")
      {}
    end
  end

  # Lấy thông tin chi tiết về adset
  def get_adset_info(adset_id)
    return {} unless adset_id.present?

    begin
      response = self.class.get(
        "/#{@api_version}/#{adset_id}",
        query: {
          access_token: @access_token,
          fields: 'id,name,status,targeting,insights{impressions,clicks,spend,cpm,cpc,ctr}'
        }
      )

      if response.success?
        parse_adset_response(response.parsed_response)
      else
        Rails.logger.error("Facebook Ads API error for adset #{adset_id}: #{response.body}")
        {}
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching adset info for #{adset_id}: #{e.message}")
      {}
    end
  end

  # Lấy thông tin tổng hợp cho một ads tracking record
  def get_comprehensive_ads_info(facebook_tracking)
    result = {
      ad_info: {},
      campaign_info: {},
      adset_info: {},
      performance_metrics: {}
    }

    # Lấy thông tin ad
    if facebook_tracking.ad_id.present?
      result[:ad_info] = get_ad_info(facebook_tracking.ad_id)
    end

    # Lấy thông tin campaign
    if facebook_tracking.campaign_id.present?
      result[:campaign_info] = get_campaign_info(facebook_tracking.campaign_id)
    end

    # Lấy thông tin adset
    if facebook_tracking.adset_id.present?
      result[:adset_info] = get_adset_info(facebook_tracking.adset_id)
    end

    # Tính toán metrics tổng hợp
    result[:performance_metrics] = calculate_performance_metrics(result)

    result
  end

  private

  def parse_ad_response(response)
    {
      id: response['id'],
      name: response['name'],
      status: response['status'],
      campaign_id: response['campaign_id'],
      adset_id: response['adset_id'],
      creative: parse_creative_data(response['creative']),
      insights: parse_insights_data(response['insights'])
    }
  end

  def parse_campaign_response(response)
    {
      id: response['id'],
      name: response['name'],
      status: response['status'],
      objective: response['objective'],
      insights: parse_insights_data(response['insights'])
    }
  end

  def parse_adset_response(response)
    {
      id: response['id'],
      name: response['name'],
      status: response['status'],
      targeting: response['targeting'],
      insights: parse_insights_data(response['insights'])
    }
  end

  def parse_creative_data(creative)
    return {} unless creative.present?

    {
      title: creative['title'],
      body: creative['body'],
      image_url: creative['image_url'],
      video_id: creative['video_id']
    }
  end

  def parse_insights_data(insights)
    return {} unless insights.present? && insights['data'].present?

    data = insights['data'].first || {}
    {
      impressions: data['impressions']&.to_i || 0,
      clicks: data['clicks']&.to_i || 0,
      spend: data['spend']&.to_f || 0.0,
      cpm: data['cpm']&.to_f || 0.0,
      cpc: data['cpc']&.to_f || 0.0,
      ctr: data['ctr']&.to_f || 0.0
    }
  end

  def calculate_performance_metrics(data)
    ad_insights = data[:ad_info][:insights] || {}
    campaign_insights = data[:campaign_info][:insights] || {}
    adset_insights = data[:adset_info][:insights] || {}

    {
      total_impressions: [ad_insights[:impressions], campaign_insights[:impressions], adset_insights[:impressions]].compact.max || 0,
      total_clicks: [ad_insights[:clicks], campaign_insights[:clicks], adset_insights[:clicks]].compact.max || 0,
      total_spend: [ad_insights[:spend], campaign_insights[:spend], adset_insights[:spend]].compact.max || 0.0,
      avg_cpm: calculate_average([ad_insights[:cpm], campaign_insights[:cpm], adset_insights[:cpm]]),
      avg_cpc: calculate_average([ad_insights[:cpc], campaign_insights[:cpc], adset_insights[:cpc]]),
      avg_ctr: calculate_average([ad_insights[:ctr], campaign_insights[:ctr], adset_insights[:ctr]])
    }
  end

  def calculate_average(values)
    valid_values = values.compact.reject(&:zero?)
    return 0.0 if valid_values.empty?

    (valid_values.sum / valid_values.size).round(2)
  end
end

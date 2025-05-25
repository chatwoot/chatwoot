class Api::V1::Accounts::FacebookDatasetController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @facebook_trackings = Current.account
                                 .facebook_ads_trackings
                                 .includes(:conversation, :contact, :inbox, :message)
                                 .recent
                                 .page(params[:page])
                                 .per(params[:per_page] || 20)

    render json: {
      data: @facebook_trackings.map(&:summary_data),
      pagination: {
        current_page: @facebook_trackings.current_page,
        total_pages: @facebook_trackings.total_pages,
        total_count: @facebook_trackings.total_count,
        per_page: params[:per_page] || 20
      }
    }
  end

  def show
    @facebook_tracking = Current.account.facebook_ads_trackings.find(params[:id])
    render json: @facebook_tracking.summary_data
  end

  def stats
    base_query = Current.account.facebook_ads_trackings

    # Filter by date range if provided
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      base_query = base_query.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    # Filter by inbox if provided
    base_query = base_query.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?

    stats = {
      total_trackings: base_query.count,
      conversions_sent: base_query.with_conversions_sent.count,
      pending_conversions: base_query.pending_conversions.count,
      unique_ads: base_query.distinct.count(:ad_id),
      unique_campaigns: base_query.where.not(campaign_id: nil).distinct.count(:campaign_id),
      unique_contacts: base_query.distinct.count(:contact_id),
      total_event_value: base_query.sum(:event_value) || 0,

      # Stats by source
      by_source: base_query.group(:referral_source).count,

      # Stats by event name
      by_event: base_query.group(:event_name).count,

      # Daily stats for the last 30 days
      daily_stats: daily_tracking_stats(base_query),

      # Top performing ads
      top_ads: top_performing_ads(base_query),

      # Conversion rate by source
      conversion_rates: conversion_rates_by_source(base_query)
    }

    render json: stats
  end

  def export
    @facebook_trackings = Current.account
                                 .facebook_ads_trackings
                                 .includes(:conversation, :contact, :inbox, :message)
                                 .recent

    # Apply filters
    @facebook_trackings = apply_filters(@facebook_trackings)

    respond_to do |format|
      format.csv do
        send_data generate_csv(@facebook_trackings),
                  filename: "facebook_dataset_tracking_#{Date.current}.csv",
                  type: 'text/csv'
      end
      format.json do
        render json: {
          data: @facebook_trackings.limit(1000).map(&:summary_data),
          total_count: @facebook_trackings.count
        }
      end
    end
  end

  def resend_conversion
    @facebook_tracking = Current.account.facebook_ads_trackings.find(params[:id])

    # Reset conversion status and resend
    @facebook_tracking.update!(
      conversion_sent: false,
      conversion_sent_at: nil,
      conversion_response: nil
    )

    Facebook::SendConversionEventJob.perform_later(@facebook_tracking.id)

    render json: {
      message: 'Conversion event queued for resending',
      tracking_id: @facebook_tracking.id
    }
  end

  def send_custom_event
    @facebook_tracking = Current.account.facebook_ads_trackings.find(params[:id])

    custom_event_params = params.require(:custom_event).permit(
      :event_name, :event_value, :currency, custom_data: {}
    )

    # Tạo custom event data
    custom_event_data = @facebook_tracking.conversion_event_data.merge(
      event_name: custom_event_params[:event_name],
      custom_data: @facebook_tracking.conversion_event_data[:custom_data].merge(
        value: custom_event_params[:event_value] || @facebook_tracking.event_value,
        currency: custom_event_params[:currency] || @facebook_tracking.currency
      ).merge(custom_event_params[:custom_data] || {})
    )

    # Gửi custom event
    Facebook::SendCustomEventJob.perform_later(@facebook_tracking.id, custom_event_data)

    render json: {
      message: 'Custom event queued for sending',
      tracking_id: @facebook_tracking.id,
      event_name: custom_event_params[:event_name]
    }
  end

  def bulk_resend
    tracking_ids = params[:tracking_ids] || []

    if tracking_ids.empty?
      render json: { error: 'No tracking IDs provided' }, status: :unprocessable_entity
      return
    end

    trackings = Current.account.facebook_ads_trackings.where(id: tracking_ids)

    trackings.update_all(
      conversion_sent: false,
      conversion_sent_at: nil,
      conversion_response: nil
    )

    trackings.find_each do |tracking|
      Facebook::SendConversionEventJob.perform_later(tracking.id)
    end

    render json: {
      message: "#{trackings.count} conversion events queued for resending",
      tracking_count: trackings.count
    }
  end

  private

  def check_authorization
    authorize(FacebookAdsTracking)
  end

  def apply_filters(query)
    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      query = query.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    # Filter by inbox
    query = query.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?

    # Filter by conversion status
    case params[:conversion_status]
    when 'sent'
      query = query.with_conversions_sent
    when 'pending'
      query = query.pending_conversions
    end

    # Filter by referral source
    query = query.where(referral_source: params[:referral_source]) if params[:referral_source].present?

    # Filter by ad ID
    query = query.where(ad_id: params[:ad_id]) if params[:ad_id].present?

    # Filter by campaign ID
    query = query.where(campaign_id: params[:campaign_id]) if params[:campaign_id].present?

    query
  end

  def daily_tracking_stats(base_query)
    30.days.ago.to_date.upto(Date.current).map do |date|
      day_query = base_query.where(created_at: date.beginning_of_day..date.end_of_day)
      {
        date: date,
        total: day_query.count,
        conversions_sent: day_query.with_conversions_sent.count,
        unique_contacts: day_query.distinct.count(:contact_id)
      }
    end
  end

  def top_performing_ads(base_query)
    base_query
      .where.not(ad_id: nil)
      .group(:ad_id, :ad_title)
      .group('facebook_ads_trackings.campaign_id')
      .select(
        'ad_id',
        'ad_title',
        'campaign_id',
        'COUNT(*) as total_trackings',
        'COUNT(CASE WHEN conversion_sent = true THEN 1 END) as conversions_sent',
        'SUM(event_value) as total_value'
      )
      .order('total_trackings DESC')
      .limit(10)
      .map do |result|
        {
          ad_id: result.ad_id,
          ad_title: result.ad_title,
          campaign_id: result.campaign_id,
          total_trackings: result.total_trackings,
          conversions_sent: result.conversions_sent,
          total_value: result.total_value || 0,
          conversion_rate: result.total_trackings > 0 ? (result.conversions_sent.to_f / result.total_trackings * 100).round(2) : 0
        }
      end
  end

  def conversion_rates_by_source(base_query)
    base_query
      .group(:referral_source)
      .select(
        'referral_source',
        'COUNT(*) as total_trackings',
        'COUNT(CASE WHEN conversion_sent = true THEN 1 END) as conversions_sent'
      )
      .map do |result|
        {
          source: result.referral_source,
          total_trackings: result.total_trackings,
          conversions_sent: result.conversions_sent,
          conversion_rate: result.total_trackings > 0 ? (result.conversions_sent.to_f / result.total_trackings * 100).round(2) : 0
        }
      end
  end

  def generate_csv(trackings)
    CSV.generate(headers: true) do |csv|
      csv << [
        'ID', 'Date', 'Contact Name', 'Contact Email', 'Inbox', 'Ad ID', 'Campaign ID',
        'Ref Parameter', 'Referral Source', 'Event Name', 'Event Value', 'Currency',
        'Conversion Sent', 'Conversion Sent At', 'Ad Title'
      ]

      trackings.find_each do |tracking|
        csv << [
          tracking.id,
          tracking.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          tracking.contact.name,
          tracking.contact.email,
          tracking.inbox.name,
          tracking.ad_id,
          tracking.campaign_id,
          tracking.ref_parameter,
          tracking.referral_source,
          tracking.event_name,
          tracking.event_value,
          tracking.currency,
          tracking.conversion_sent ? 'Yes' : 'No',
          tracking.conversion_sent_at&.strftime('%Y-%m-%d %H:%M:%S'),
          tracking.ad_title
        ]
      end
    end
  end
end

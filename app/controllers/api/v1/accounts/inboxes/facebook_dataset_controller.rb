class Api::V1::Accounts::Inboxes::FacebookDatasetController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :check_facebook_channel

  def show
    render json: {
      enabled: @inbox.channel.facebook_dataset_enabled?,
      config: @inbox.channel.facebook_dataset_config,
      tracking_stats: get_tracking_stats
    }
  end

  def update
    config = facebook_dataset_params

    # Validate required fields if enabling
    if config[:enabled] && !valid_config?(config)
      render json: { error: 'Missing required configuration fields' }, status: :unprocessable_entity
      return
    end

    @inbox.channel.update_facebook_dataset_config(config)

    render json: {
      enabled: @inbox.channel.facebook_dataset_enabled?,
      config: @inbox.channel.facebook_dataset_config,
      message: 'Facebook Dataset configuration updated successfully'
    }
  end

  def test_connection
    config = @inbox.channel.facebook_dataset_config

    unless config['enabled'] && config['pixel_id'].present? && config['access_token'].present?
      render json: { error: 'Facebook Dataset not properly configured' }, status: :unprocessable_entity
      return
    end

    begin
      # Test connection by sending a test event
      test_result = test_facebook_dataset_connection(config)

      if test_result['error'].present?
        render json: {
          success: false,
          error: test_result['error']['message'],
          details: test_result
        }, status: :unprocessable_entity
      else
        render json: {
          success: true,
          message: 'Facebook Dataset connection successful',
          details: test_result
        }
      end
    rescue StandardError => e
      render json: {
        success: false,
        error: e.message
      }, status: :internal_server_error
    end
  end

  def tracking_data
    page = params[:page] || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min

    trackings = FacebookAdsTracking
                  .where(inbox: @inbox)
                  .includes(:conversation, :contact, :message)
                  .recent
                  .page(page)
                  .per(per_page)

    render json: {
      data: trackings.map(&:summary_data),
      pagination: {
        current_page: trackings.current_page,
        total_pages: trackings.total_pages,
        total_count: trackings.total_count,
        per_page: per_page
      }
    }
  end

  def resend_conversion
    tracking = FacebookAdsTracking.find(params[:tracking_id])

    unless tracking.inbox == @inbox
      render json: { error: 'Tracking not found' }, status: :not_found
      return
    end

    # Reset conversion status and resend
    tracking.update!(conversion_sent: false, conversion_sent_at: nil, conversion_response: nil)
    Facebook::SendConversionEventJob.perform_later(tracking.id)

    render json: {
      message: 'Conversion event queued for resending',
      tracking_id: tracking.id
    }
  end

  def pixels
    begin
      facebook_service = Facebook::GetPixelsService.new(channel: @inbox.channel)
      result = facebook_service.get_pixels

      if result[:success]
        render json: {
          success: true,
          pixels: result[:pixels],
          message: "Found #{result[:pixels].length} pixels"
        }
      else
        render json: {
          success: false,
          error: result[:error],
          pixels: []
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching Facebook pixels: #{e.message}")
      render json: {
        success: false,
        error: 'Failed to fetch Facebook pixels. Please check your Facebook connection.',
        pixels: []
      }, status: :internal_server_error
    end
  end

  def generate_token
    pixel_id = params[:pixel_id]

    if pixel_id.blank?
      render json: {
        success: false,
        error: 'Pixel ID is required'
      }, status: :unprocessable_entity
      return
    end

    begin
      facebook_service = Facebook::GenerateTokenService.new(
        channel: @inbox.channel,
        pixel_id: pixel_id
      )
      result = facebook_service.generate_conversions_api_token

      if result[:success]
        render json: {
          success: true,
          access_token: result[:access_token],
          message: 'Access token generated successfully'
        }
      else
        render json: {
          success: false,
          error: result[:error]
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("Error generating Facebook access token: #{e.message}")
      render json: {
        success: false,
        error: 'Failed to generate access token. Please check your Facebook permissions.'
      }, status: :internal_server_error
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def check_facebook_channel
    unless @inbox.channel.is_a?(Channel::FacebookPage)
      render json: { error: 'This feature is only available for Facebook channels' }, status: :unprocessable_entity
    end
  end

  def facebook_dataset_params
    params.require(:facebook_dataset).permit(
      :enabled,
      :pixel_id,
      :access_token,
      :test_event_code,
      :default_event_name,
      :default_event_value,
      :default_currency,
      :auto_send_conversions
    )
  end

  def valid_config?(config)
    config[:pixel_id].present? && config[:access_token].present?
  end

  def get_tracking_stats
    base_query = FacebookAdsTracking.where(inbox: @inbox)

    {
      total_trackings: base_query.count,
      conversions_sent: base_query.with_conversions_sent.count,
      pending_conversions: base_query.pending_conversions.count,
      last_30_days: base_query.where(created_at: 30.days.ago..Time.current).count,
      unique_ads: base_query.distinct.count(:ad_id),
      unique_campaigns: base_query.where.not(campaign_id: nil).distinct.count(:campaign_id)
    }
  end

  def test_facebook_dataset_connection(config)
    pixel_id = config['pixel_id']
    access_token = config['access_token']
    test_event_code = config['test_event_code']

    url = "https://graph.facebook.com/v18.0/#{pixel_id}/events"

    # Send a test event
    test_payload = {
      data: [{
        event_name: 'Test',
        event_time: Time.current.to_i,
        action_source: 'chat',
        user_data: {
          external_id: 'test_user_123'
        },
        custom_data: {
          content_name: 'Test Event',
          content_category: 'testing',
          value: 0,
          currency: 'USD'
        }
      }],
      access_token: access_token
    }

    test_payload[:test_event_code] = test_event_code if test_event_code.present?

    response = HTTParty.post(
      url,
      body: test_payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 30
    )

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    { 'error' => { 'message' => 'Invalid response format' } }
  rescue HTTParty::Error, Net::TimeoutError => e
    { 'error' => { 'message' => e.message } }
  end
end

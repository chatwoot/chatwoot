class Facebook::ReferralProcessorService
  include Rails.application.routes.url_helpers

  def initialize(inbox:, contact_inbox:, params:)
    @inbox = inbox
    @contact_inbox = contact_inbox
    @params = params
    @response = Integrations::Facebook::MessageParser.new(@params)
  end

  def perform
    return unless @response.referral?

    process_referral_data
  end

  private

  def process_referral_data
    # Tìm hoặc tạo conversation cho referral
    conversation = find_or_create_conversation

    # Lưu trữ Facebook ads tracking data
    save_facebook_ads_tracking(conversation)

    # Tạo message cho referral nếu cần
    create_referral_message(conversation) if should_create_referral_message?

    conversation
  end

  def find_or_create_conversation
    # Tìm conversation hiện tại hoặc tạo mới
    conversation = @contact_inbox.conversations.last

    if conversation.nil? || conversation.resolved?
      conversation = ::Conversation.create!(
        account: @inbox.account,
        inbox: @inbox,
        contact: @contact_inbox.contact,
        contact_inbox: @contact_inbox,
        additional_attributes: {
          referral_source: @response.referral_source,
          referral_type: @response.referral_type,
          ref_parameter: @response.referral_ref
        }
      )
    else
      # Cập nhật conversation với referral data
      conversation.update!(
        additional_attributes: conversation.additional_attributes.merge(
          referral_source: @response.referral_source,
          referral_type: @response.referral_type,
          ref_parameter: @response.referral_ref
        )
      )
    end

    conversation
  end

  def save_facebook_ads_tracking(conversation)
    return unless @response.referral_data.present?

    begin
      tracking_data = {
        conversation: conversation,
        contact: @contact_inbox.contact,
        inbox: @inbox,
        account: @inbox.account,
        ref_parameter: @response.referral_ref,
        referral_source: @response.referral_source,
        referral_type: @response.referral_type,
        ad_id: @response.referral_ad_id,
        campaign_id: @response.referral_campaign_id,
        adset_id: @response.referral_adset_id,
        raw_referral_data: @response.referral_data
      }

      # Thêm ads context data nếu có
      if @response.referral_ads_context_data.present?
        ads_context = @response.referral_ads_context_data
        tracking_data.merge!(
          ad_title: ads_context['ad_title'],
          ad_photo_url: ads_context['photo_url'],
          ad_video_url: ads_context['video_url']
        )
      end

      facebook_tracking = FacebookAdsTracking.create!(tracking_data)
      facebook_tracking.extract_campaign_and_adset_ids
      facebook_tracking.save! if facebook_tracking.changed?

      Rails.logger.info("Saved Facebook ads tracking data: #{facebook_tracking.id} for conversation #{conversation.id}")

      # Gửi conversion event nếu được cấu hình
      schedule_conversion_event(facebook_tracking) if should_send_conversion_event?

      facebook_tracking
    rescue StandardError => e
      Rails.logger.error("Error saving Facebook ads tracking data: #{e.message}")
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
      nil
    end
  end

  def should_create_referral_message?
    # Tạo message thông báo về nguồn referral
    @inbox.channel.provider_config&.dig('create_referral_message') != false
  end

  def create_referral_message(conversation)
    message_content = build_referral_message_content

    message = conversation.messages.create!(
      account: @inbox.account,
      inbox: @inbox,
      message_type: :activity,
      content: message_content,
      content_attributes: {
        referral_data: @response.referral_data
      }
    )

    Rails.logger.info("Created referral message: #{message.id} for conversation #{conversation.id}")
    message
  end

  def build_referral_message_content
    case @response.referral_source
    when 'SHORTLINK'
      "Customer came from Facebook ad shortlink (ref: #{@response.referral_ref})"
    when 'ADS'
      ad_title = @response.referral_ads_context_data&.dig('ad_title')
      if ad_title.present?
        "Customer came from Facebook ad: #{ad_title} (ref: #{@response.referral_ref})"
      else
        "Customer came from Facebook ad (ref: #{@response.referral_ref})"
      end
    when 'MESSENGER_CODE'
      "Customer scanned Messenger code (ref: #{@response.referral_ref})"
    when 'DISCOVER_TAB'
      "Customer found page through Discover tab (ref: #{@response.referral_ref})"
    else
      "Customer came from #{@response.referral_source} (ref: #{@response.referral_ref})"
    end
  end

  def should_send_conversion_event?
    # Kiểm tra cấu hình inbox hoặc account
    @inbox.channel.respond_to?(:facebook_dataset_enabled?) && @inbox.channel.facebook_dataset_enabled?
  end

  def schedule_conversion_event(facebook_tracking)
    Facebook::SendConversionEventJob.perform_later(facebook_tracking.id)
  end
end

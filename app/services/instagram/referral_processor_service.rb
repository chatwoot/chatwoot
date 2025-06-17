class Instagram::ReferralProcessorService
  include Rails.application.routes.url_helpers

  def initialize(inbox:, contact_inbox:, params:)
    @inbox = inbox
    @contact_inbox = contact_inbox
    @params = params
    @response = Integrations::Instagram::MessageParser.new(@params)
  end

  def perform
    return unless @response.referral?

    process_referral_data
  end

  private

  def process_referral_data
    # Tìm hoặc tạo conversation cho referral
    conversation = find_or_create_conversation

    # Lưu trữ Instagram ads tracking data
    save_instagram_ads_tracking(conversation)

    # Tạo message cho referral nếu cần
    create_referral_message(conversation) if should_create_referral_message?

    conversation
  end

  def find_or_create_conversation
    # Tìm conversation hiện tại hoặc tạo mới
    conversation = @contact_inbox.conversations.last

    if conversation.blank? || conversation.resolved?
      conversation = ::Conversation.create!(
        account: @inbox.account,
        inbox: @inbox,
        contact: @contact_inbox.contact,
        contact_inbox: @contact_inbox,
        additional_attributes: {
          initiated_at: {
            timestamp: Time.zone.now
          }
        }
      )
    end

    conversation
  end

  def create_referral_message(conversation)
    # Tạo message thông báo về nguồn referral
    referral_message_content = build_referral_message_content

    conversation.messages.create!(
      account: @inbox.account,
      inbox: @inbox,
      message_type: :incoming,
      content: referral_message_content,
      source_id: "referral_#{@response.referral_ref}_#{Time.current.to_i}",
      sender: @contact_inbox.contact,
      content_type: 'text',
      content_attributes: {
        referral_data: @response.referral_data
      }
    )
  end

  def build_referral_message_content
    source = @response.referral_source&.humanize || 'Instagram'
    ref = @response.referral_ref
    ad_title = @response.referral_ads_context_data&.dig('ad_title')

    content = "🎯 Khách hàng đến từ #{source}"
    content += " (Ref: #{ref})" if ref.present?
    content += "\n📢 Quảng cáo: #{ad_title}" if ad_title.present?

    content
  end

  def save_instagram_ads_tracking(conversation)
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

      # Sử dụng chung FacebookAdsTracking model vì Instagram cũng là Meta platform
      instagram_tracking = FacebookAdsTracking.create!(tracking_data)
      instagram_tracking.extract_campaign_and_adset_ids
      instagram_tracking.save! if instagram_tracking.changed?

      Rails.logger.info("Saved Instagram ads tracking data: #{instagram_tracking.id} for conversation #{conversation.id}")

      # Gửi conversion event nếu được cấu hình
      schedule_conversion_event(instagram_tracking) if should_send_conversion_event?

      instagram_tracking
    rescue StandardError => e
      Rails.logger.error("Error saving Instagram ads tracking data: #{e.message}")
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
      nil
    end
  end

  def should_create_referral_message?
    # Tạo message thông báo về nguồn referral
    @inbox.channel.provider_config&.dig('create_referral_message') != false
  end

  def should_send_conversion_event?
    # Kiểm tra cấu hình inbox hoặc account
    @inbox.channel.respond_to?(:facebook_dataset_enabled?) && @inbox.channel.facebook_dataset_enabled?
  end

  def schedule_conversion_event(tracking)
    # Schedule job để gửi conversion event
    Facebook::SendConversionEventJob.perform_later(tracking.id)
  end
end

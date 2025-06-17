# This class creates both outgoing messages from chatwoot and echo outgoing messages based on the flag `outgoing_echo`
# Assumptions
# 1. Incase of an outgoing message which is echo, source_id will NOT be nil,
#    based on this we are showing "not sent from chatwoot" message in frontend
#    Hence there is no need to set user_id in message for outgoing echo messages.

class Messages::Facebook::MessageBuilder < Messages::Messenger::MessageBuilder
  attr_reader :response

  def initialize(response, inbox, outgoing_echo: false)
    super()
    @response = response
    @inbox = inbox
    @outgoing_echo = outgoing_echo
    @sender_id = (@outgoing_echo ? @response.recipient_id : @response.sender_id)
    @message_type = (@outgoing_echo ? :outgoing : :incoming)
    @attachments = (@response.attachments || [])
  end

  def perform
    # This channel might require reauthorization, may be owner might have changed the fb password
    return if @inbox.channel.reauthorization_required?

    ActiveRecord::Base.transaction do
      build_contact_inbox
      build_message
    end
  rescue Koala::Facebook::AuthenticationError => e
    Rails.logger.warn("Facebook authentication error for inbox: #{@inbox.id} with error: #{e.message}")
    Rails.logger.error e

    # Thử refresh token trước khi đánh dấu cần reauthorization
    attempt_token_refresh_on_error

    @inbox.channel.authorization_error!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    true
  end

  private

  def build_contact_inbox
    # Lấy thông tin liên hệ từ params
    contact_attributes = contact_params

    # Ghi log thông tin liên hệ để debug
    Rails.logger.info("Facebook contact attributes for sender #{@sender_id}: #{contact_attributes.inspect}")

    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: @sender_id,
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    # Cập nhật avatar sau khi tạo contact
    update_contact_avatar if @contact_inbox.present? && @contact_inbox.contact.present?
  end

  # Cập nhật avatar cho contact sau khi đã tạo
  def update_contact_avatar
    contact = @contact_inbox.contact
    return if contact.avatar.attached?

    # Sử dụng service để lấy URL avatar trực tiếp
    avatar_url = Facebook::FetchProfileService.new(
      user_id: @sender_id,
      page_access_token: @inbox.channel.page_access_token
    ).get_direct_avatar_url(@sender_id, @inbox.channel.page_access_token)

    Rails.logger.info("Scheduling avatar update for contact #{contact.id} with direct URL from Facebook")

    # Sử dụng perform_later với delay để tránh blocking và để đảm bảo contact đã được lưu vào database
    Avatar::AvatarFromUrlJob.set(wait: 5.seconds).perform_later(contact, avatar_url)
  end

  def build_message
    @message = conversation.messages.create!(message_params)

    @attachments.each do |attachment|
      process_attachment(attachment)
    end

    # Lưu trữ Facebook ads tracking data nếu có referral
    save_facebook_ads_tracking if @response.respond_to?(:referral?) && @response.referral?
  end

  def conversation
    @conversation ||= set_conversation_based_on_inbox_config
  end

  def set_conversation_based_on_inbox_config
    if @inbox.lock_to_single_conversation
      Conversation.where(conversation_params).order(created_at: :desc).first || build_conversation
    else
      find_or_build_for_multiple_conversations
    end
  end

  def find_or_build_for_multiple_conversations
    # If lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    last_conversation = Conversation.where(conversation_params).where.not(status: :resolved).order(created_at: :desc).first
    return build_conversation if last_conversation.nil?

    last_conversation
  end

  def build_conversation
    Conversation.create!(conversation_params.merge(
                           contact_inbox_id: @contact_inbox.id
                         ))
  end

  def location_params(attachment)
    lat = attachment['payload']['coordinates']['lat']
    long = attachment['payload']['coordinates']['long']
    {
      external_url: attachment['url'],
      coordinates_lat: lat,
      coordinates_long: long,
      fallback_title: attachment['title']
    }
  end

  def fallback_params(attachment)
    {
      fallback_title: attachment['title'],
      external_url: attachment['url']
    }
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact_inbox.contact_id
    }
  end

  def message_params
    params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: @message_type,
      content: response.content,
      source_id: response.identifier,
      content_attributes: {
        in_reply_to_external_id: response.in_reply_to_external_id
      },
      sender: @outgoing_echo ? nil : @contact_inbox.contact
    }

    # Thêm payload vào content_attributes nếu là postback message
    if response.respond_to?(:postback?) && response.postback?
      params[:content_attributes][:postback_payload] = response.postback_payload
    end

    params
  end

  def process_contact_params_result(result)
    # Tạo URL avatar trực tiếp từ Facebook Graph API nếu có sender_id
    avatar_url = if @sender_id.present?
                  # Sử dụng service để lấy URL avatar trực tiếp
                  Facebook::FetchProfileService.new(
                    user_id: @sender_id,
                    page_access_token: @inbox.channel.page_access_token
                  ).get_direct_avatar_url(@sender_id, @inbox.channel.page_access_token)
                else
                  result['profile_pic']
                end

    Rails.logger.info("Facebook avatar URL for sender #{@sender_id}: #{avatar_url}")

    {
      name: "#{result['first_name'] || 'John'} #{result['last_name'] || 'Doe'}",
      account_id: @inbox.account_id,
      avatar_url: avatar_url
    }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def contact_params
    # Sử dụng service mới để lấy thông tin người dùng từ Facebook
    result = Facebook::FetchProfileService.new(
      user_id: @sender_id,
      page_access_token: @inbox.channel.page_access_token
    ).perform

    # Xử lý lỗi xác thực
    if result[:error] == 'authentication_error'
      Rails.logger.warn("Facebook authentication error for inbox: #{@inbox.id} with error: #{result[:message]}")
      @inbox.channel.authorization_error!
      raise Koala::Facebook::AuthenticationError, result[:message]
    end

    # Ghi log lỗi client nếu có
    if result[:error] == 'client_error'
      if result[:message].to_s.include?('2018218')
        Rails.logger.warn "Facebook client error for sender #{@sender_id}: #{result[:message]}"
      else
        Rails.logger.warn "Facebook client error for sender #{@sender_id}: #{result[:message]}"
        ChatwootExceptionTracker.new(StandardError.new(result[:message]), account: @inbox.account).capture_exception unless @outgoing_echo
      end
    end

    # Ghi log lỗi không mong đợi nếu có
    if result[:error] == 'unexpected_error'
      Rails.logger.error "Facebook unexpected error for sender #{@sender_id}: #{result[:message]}"
      ChatwootExceptionTracker.new(StandardError.new(result[:message]), account: @inbox.account).capture_exception
    end

    # Xử lý kết quả và trả về thông tin liên hệ
    process_contact_params_result(result)
  end

  # Thử refresh token khi gặp lỗi authentication
  def attempt_token_refresh_on_error
    return unless @inbox.channel.is_a?(Channel::FacebookPage)

    begin
      refresh_service = Facebook::RefreshOauthTokenService.new(channel: @inbox.channel)
      result = refresh_service.attempt_token_refresh

      if refresh_service.token_valid?
        Rails.logger.info("Successfully refreshed Facebook token after authentication error for inbox #{@inbox.id}")
      else
        Rails.logger.warn("Failed to refresh Facebook token after authentication error for inbox #{@inbox.id}")
      end
    rescue StandardError => e
      Rails.logger.error("Error during token refresh attempt for inbox #{@inbox.id}: #{e.message}")
    end
  end

  # Lưu trữ Facebook ads tracking data
  def save_facebook_ads_tracking
    return unless @response.referral_data.present?

    begin
      tracking_data = {
        conversation: conversation,
        message: @message,
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

    rescue StandardError => e
      Rails.logger.error("Error saving Facebook ads tracking data: #{e.message}")
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    end
  end

  # Kiểm tra xem có nên gửi conversion event không
  def should_send_conversion_event?
    # Kiểm tra cấu hình inbox hoặc account
    @inbox.channel.respond_to?(:facebook_dataset_enabled?) && @inbox.channel.facebook_dataset_enabled?
  end

  # Lên lịch gửi conversion event
  def schedule_conversion_event(facebook_tracking)
    Facebook::SendConversionEventJob.perform_later(facebook_tracking.id)
  end

  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end

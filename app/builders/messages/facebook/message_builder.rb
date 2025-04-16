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
    @inbox.channel.authorization_error!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    true
  end

  private

  def build_contact_inbox
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: @sender_id,
      inbox: @inbox,
      contact_attributes: contact_params
    ).perform
  end

  def build_message
    @message = conversation.messages.create!(message_params)

    @attachments.each do |attachment|
      process_attachment(attachment)
    end
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
                  "https://graph.facebook.com/#{@sender_id}/picture?type=large&access_token=#{@inbox.channel.page_access_token}"
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
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end

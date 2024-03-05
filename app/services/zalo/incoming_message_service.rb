class Zalo::IncomingMessageService
  include ::FileTypeHelper

  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    if params[:event_name] == 'user_submit_info'
      update_contact_from_shared_info
      return
    end

    first_message_processing if @contact.messages.empty?
    set_conversation
    @message = @conversation.messages.create!(message_params)
    Rails.logger.info('Message created')

    @message.content_attributes[:in_reply_to_external_id] = params[:message][:quote_msg_id] if params[:message][:quote_msg_id]

    Rails.logger.info('Attaching media')
    attach_media
    @message.save!
  end

  private

  def account
    @account ||= @inbox.account
  end

  def channel
    @channel ||= @inbox.channel
  end

  def url_getprofile
    'https://openapi.zalo.me/v2.0/oa/getprofile'
  end

  def first_message_processing
    Rails.logger.info('First message processing')
    # try to get user info from followed user first
    update_contact_from_profile
    # request user info for unfollowed user
    request_user_info if @contact.name == params[:sender][:id]
  end

  def get_profile(user_id, access_token)
    HTTParty.get(
      url_getprofile,
      headers: { 'access_token' => access_token },
      query: { data: { user_id: user_id }.to_json }
    )
  end

  def request_user_info
    body = request_user_info_body
    channel.send_message_cs(body, channel.oa_access_token)
  end

  def request_user_info_body
    {
      recipient: {
        user_id: params[:sender][:id]
      },
      # TODO: Need to personalize the below info
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'request_user_info',
            elements: [{
              title: 'HoaTieu CRM cảm ơn bạn đã liên hệ',
              subtitle: 'Nhấp vào đây để cung cấp thông tin của bạn',
              image_url: 'https://noventiq.si/uploads/resizer/images/2b68b5/ed7a86/d2b6d2/origin-mode1-760x362.jpg'
            }]
          }
        }
      }
    }
  end

  def update_contact_from_profile
    response = get_profile(params[:sender][:id], channel.oa_access_token)
    return unless (response['error']).zero?

    @contact.update!(name: response['data']['display_name'])
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, response['data']['avatars']['240'])
  end

  def update_contact_from_shared_info
    phone_number = params[:info][:phone].to_s
    phone_number.prepend('+') unless phone_number.start_with?('+')

    @contact.update!(
      name: params[:info][:name],
      phone_number: phone_number
    )
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: params[:sender][:id],
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def message_params
    {
      content: params[:message][:text],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:message][:msg_id]
    }
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where
                                    .not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: params[:sender][:id]
    }
  end

  def file_content_type(media)
    return :image if %w[image gif sticker].include?(media[:type])
    return :audio if media[:type] == 'audio'
    return :video if media[:type] == 'video'

    file_type(media[:payload][:type])
  end

  def attach_media
    return if params[:message][:attachments].blank?

    params[:message][:attachments].each do |media|
      case media[:type]
      when 'link'
        @message.content = "Link: #{media[:payload][:url]}"
      when 'location'
        attach_location(media)
      else
        # File size bigger than 10Mb will show as link
        if media[:type] == 'file' && media[:payload][:size].to_i > 10 * 1024 * 1024
          @message.content = "File to download: #{media[:payload][:url]}"
          next
        end

        attach_file(media)
      end
    end
  end

  def attach_location(media)
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :location,
      coordinates_lat: media[:payload][:coordinates][:latitude],
      coordinates_long: media[:payload][:coordinates][:longitude]
    )
  end

  def attach_file(media)
    Rails.logger.info("Attaching file #{media}")
    attachment_file = Down.download(media[:payload][:url])
    Rails.logger.info("Downloaded file #{media}")
    file_name = media[:payload][:name] || attachment_file.original_filename
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(media),
      file: {
        io: attachment_file,
        filename: file_name,
        content_type: attachment_file.content_type
      }
    )
    @message.content_type = 'sticker' if media[:type] == 'sticker'
  end
end

# This class creates both outgoing messages from chatwoot and echo outgoing messages based on the flag `outgoing_echo`
# Assumptions
# 1. Incase of an outgoing message which is echo, source_id will NOT be nil,
#    based on this we are showing "not sent from chatwoot" message in frontend
#    Hence there is no need to set user_id in message for outgoing echo messages.

class Messages::Facebook::MessageBuilder
  attr_reader :response

  def initialize(response, inbox, outgoing_echo: false)
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
      build_contact
      build_message
    end
  rescue Koala::Facebook::AuthenticationError
    Rails.logger.info "Facebook Authorization expired for Inbox #{@inbox.id}"
  rescue StandardError => e
    Raven.capture_exception(e)
    true
  end

  private

  def contact
    @contact ||= @inbox.contact_inboxes.find_by(source_id: @sender_id)&.contact
  end

  def build_contact
    return if contact.present?

    @contact = Contact.create!(contact_params.except(:remote_avatar_url))
    ContactAvatarJob.perform_later(@contact, contact_params[:remote_avatar_url]) if contact_params[:remote_avatar_url]
    @contact_inbox = ContactInbox.create(contact: contact, inbox: @inbox, source_id: @sender_id)
  end

  def build_message
    @message = conversation.messages.create!(message_params)
    @attachments.each do |attachment|
      process_attachment(attachment)
    end
  end

  def process_attachment(attachment)
    return if attachment['type'].to_sym == :template

    attachment_obj = @message.attachments.new(attachment_params(attachment).except(:remote_file_url))
    attachment_obj.save!
    attach_file(attachment_obj, attachment_params(attachment)[:remote_file_url]) if attachment_params(attachment)[:remote_file_url]
  end

  def attach_file(attachment, file_url)
    file_resource = LocalResource.new(file_url)
    attachment.file.attach(io: file_resource.file, filename: file_resource.filename, content_type: file_resource.encoding)
  rescue *ExceptionList::URI_EXCEPTIONS => e
    Rails.logger.info "invalid url #{file_url} : #{e.message}"
  end

  def conversation
    @conversation ||= Conversation.find_by(conversation_params) || build_conversation
  end

  def build_conversation
    @contact_inbox ||= contact.contact_inboxes.find_by!(source_id: @sender_id)
    Conversation.create!(conversation_params.merge(
                           contact_inbox_id: @contact_inbox.id
                         ))
  end

  def attachment_params(attachment)
    file_type = attachment['type'].to_sym
    params = { file_type: file_type, account_id: @message.account_id }

    if [:image, :file, :audio, :video].include? file_type
      params.merge!(file_type_params(attachment))
    elsif file_type == :location
      params.merge!(location_params(attachment))
    elsif file_type == :fallback
      params.merge!(fallback_params(attachment))
    end

    params
  end

  def file_type_params(attachment)
    {
      external_url: attachment['payload']['url'],
      remote_file_url: attachment['payload']['url']
    }
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
      contact_id: contact.id
    }
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: @message_type,
      content: response.content,
      source_id: response.identifier,
      sender: @outgoing_echo ? nil : contact
    }
  end

  def contact_params
    begin
      k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
      result = k.get_object(@sender_id) || {}
    rescue Koala::Facebook::AuthenticationError
      @inbox.channel.authorization_error!
      raise
    rescue StandardError => e
      result = {}
      Raven.capture_exception(e)
    end
    {
      name: "#{result['first_name'] || 'John'} #{result['last_name'] || 'Doe'}",
      account_id: @inbox.account_id,
      remote_avatar_url: result['profile_pic'] || ''
    }
  end
end

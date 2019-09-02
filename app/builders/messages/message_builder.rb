require 'open-uri'
class Messages::MessageBuilder
  attr_accessor :response

  def initialize response, inbox, outgoing_echo=false
    @response = response
    @inbox = inbox
    @sender_id = (outgoing_echo ? @response.recipient_id : @response.sender_id)
    @message_type = (outgoing_echo ? :outgoing : :incoming)
  end

  def perform #for incoming
    begin
      ActiveRecord::Base.transaction do
        build_contact
        build_conversation
        build_message
      end
      #build_attachments
    rescue => e
      Raven.capture_exception(e)
      #change this asap
      return true

    end
  end

  private

  def build_attachments

  end

  def contact
    @contact ||= @inbox.contacts.find_by(source_id: @sender_id)
  end

  def build_contact
    if contact.nil?
      @contact = @inbox.contacts.create!(contact_params)
    end
  end

  def build_message
    @message = @conversation.messages.new(message_params)
    (response.attachments || []).each do |attachment|
      @message.build_attachment(attachment_params(attachment))
    end
    @message.save!
  end

  def build_conversation
    if conversation.nil?
      ::Conversation.create!(conversation_params)
    end
  end

  def contact
    @contact ||= @inbox.contacts.find_by(source_id: @sender_id)
  end

  def conversation
    @conversation ||= ::Conversation.find_by(conversation_params)
  end

  def attachment_params(attachment)
    file_type = attachment['type'].to_sym
    params = {
      file_type: file_type,
      account_id: @message.account_id
    }
    if [:image, :file, :audio, :video].include? file_type
      params.merge!(
        {
        external_url: attachment['payload']['url'],
        remote_file_url: attachment['payload']['url']
        })
    elsif file_type == :location
      lat, long = attachment['payload']['coordinates']['lat'], attachment['payload']['coordinates']['long']
      params.merge!(
        {
          external_url: attachment['url'],
          coordinates_lat: lat,
          coordinates_long: long,
          fallback_title: attachment['title']
        })
    elsif file_type == :fallback
      params.merge!(
      {
        fallback_title: attachment['title'],
        external_url: attachment['url']
      })
    end
    params
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      sender_id: contact.id
    }
  end

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: @message_type,
      content: response.content,
      fb_id: response.identifier
    }
  end

  def contact_params
    if @inbox.facebook?
      k = Koala::Facebook::API.new(@inbox.channel.page_access_token)
      begin
        result = k.get_object(@sender_id)
      rescue => e
        result = {}
        Raven.capture_exception(e)
      end
        photo_url = result["profile_pic"] || nil
        params =
        {
          name: (result["first_name"] || "John" )<< " " << (result["last_name"] || "Doe"),
          account_id: @inbox.account_id,
          source_id: @sender_id,
          remote_avatar_url: photo_url
        }
    end
  end
end

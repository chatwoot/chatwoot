class Line::IncomingMessageService
  include ::FileTypeHelper
  pattr_initialize [:inbox!, :params!]

  def perform
    line_contact_info
    set_contact
    set_conversation
    @message = @conversation.messages.create(
      content: params[:events].first["message"]["text"],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: (params[:events].first["message"]["id"]).to_s
    )
    @message.save!
  end

  private

  def account
    @account ||= inbox.account
  end

  def line_contact_info
    @line_contact_info ||= JSON.parse(client.get_profile(params[:events].first["source"]["userId"]).body)
  end

  def set_contact
    contact_inbox = ::ContactBuilder.new(
      source_id: line_contact_info["userId"],
      inbox: inbox,
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

  def set_conversation
    @conversation = @contact_inbox.conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: line_contact_info["displayName"],
      avatar_url: line_contact_info["pictureUrl"]
    }
  end

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_id = inbox.channel.line_channel_id
      config.channel_secret = inbox.channel.line_channel_secret
      config.channel_token = inbox.channel.line_channel_token
    }
  end
end

class Line::IncomingMessageService
  include ::FileTypeHelper
  pattr_initialize [:inbox!, :params!]

  def perform
    line_contact_info
    set_contact
    set_conversation
    # TODO: iterate over the events and handle the attachments in future
    # https://github.com/line/line-bot-sdk-ruby#synopsis
    @message = @conversation.messages.create(
      content: params[:events].first['message']['text'],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: (params[:events].first['message']['id']).to_s
    )
    @message.save!
  end

  private

  def account
    @account ||= inbox.account
  end

  def line_contact_info
    @line_contact_info ||= JSON.parse(inbox.channel.client.get_profile(params[:events].first['source']['userId']).body)
  end

  def set_contact
    contact_inbox = ::ContactBuilder.new(
      source_id: line_contact_info['userId'],
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
      name: line_contact_info['displayName'],
      avatar_url: line_contact_info['pictureUrl']
    }
  end
end

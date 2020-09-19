class SupportMailbox < ApplicationMailbox
  attr_accessor :channel, :account, :inbox, :conversation, :processed_mail

  before_processing :find_channel,
                    :load_account,
                    :load_inbox,
                    :decorate_mail

  def process
    find_or_create_contact
    create_conversation
    create_message
    add_attachments_to_message
  end

  private

  def find_channel
    mail.to.each do |email|
      @channel = Channel::Email.find_by(email: email)
      break if @channel.present?
    end
    raise 'Email channel/inbox not found' if @channel.nil?

    @channel
  end

  def load_account
    @account = @channel.account
  end

  def load_inbox
    @inbox = @channel.inbox
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @account)
  end

  def create_conversation
    @conversation = ::Conversation.create!({
                                             account_id: @account.id,
                                             inbox_id: @inbox.id,
                                             contact_id: @contact.id,
                                             contact_inbox_id: @contact_inbox.id,
                                             additional_attributes: {
                                               source: 'email',
                                               initiated_at: {
                                                 timestamp: Time.now.utc
                                               }
                                             }
                                           })
  end

  def find_or_create_contact
    @contact = @inbox.contacts.find_by(email: processed_mail.from.first)
    if @contact.present?
      @contact_inbox = ContactInbox.find_by(inbox: @inbox, contact: @contact)
    else
      create_contact
    end
  end

  def create_contact
    @contact_inbox = ::ContactBuilder.new(
      source_id: "email:#{processed_mail.message_id}",
      inbox: @inbox,
      contact_attributes: {
        name: identify_contact_name,
        email: processed_mail.from.first,
        additional_attributes: {
          source_id: "email:#{processed_mail.message_id}"
        }
      }
    ).perform
    @contact = @contact_inbox.contact
  end

  def identify_contact_name
    processed_mail.from.first.split('@').first
  end

  def create_message
    @message = @conversation.messages.create(
      account_id: @conversation.account_id,
      sender: @contact,
      content: processed_mail.text_content[:reply],
      inbox_id: @conversation.inbox_id,
      message_type: 'incoming',
      content_type: 'incoming_email',
      source_id: processed_mail.message_id,
      content_attributes: {
        email: processed_mail.serialized_data
      }
    )
  end

  def add_attachments_to_message
    processed_mail.attachments.each do |mail_attachment|
      attachment = @message.attachments.new(
        account_id: @conversation.account_id,
        file_type: 'file'
      )
      attachment.file.attach(mail_attachment[:blob])
    end
    @message.save!
  end
end

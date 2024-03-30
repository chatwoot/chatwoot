class Webhooks::NotificaMeEventsJob < ApplicationJob
  queue_as :default

=begin
  {
    "type":"MESSAGE_STATUS",
    "timestamp":"2024-03-29 07:55:58 pm",
    "subscriptionId":"f44d13f2-fb66-4dc8-85fe-7973b296dd3a",
    "channel":"telegram",
    "messageId":"c09b633a-ceab-4bb5-854a-5ce5d27717cb",
    "contentIndex":0,
    "messageStatus":{
       "timestamp":"2024-03-29 07:55:58 pm",
       "code":"REJECTED",
       "description":"The message was rejected by the provider"
    },
    "hub_access_token":"f20018fa-eb17-11ee-880c-0efa6ad28f4f.f44d13f2-fb66-4dc8-85fe-7973b296dd3a",
    "controller":"webhooks/notifica_me",
    "action":"process_payload",
    "channel_id":"f44d13f2-fb66-4dc8-85fe-7973b296dd3a",
    "notifica_me":{
       "type":"MESSAGE_STATUS",
       "timestamp":"2024-03-29 07:55:58 pm",
       "subscriptionId":"f44d13f2-fb66-4dc8-85fe-7973b296dd3a",
       "channel":"telegram",
       "messageId":"c09b633a-ceab-4bb5-854a-5ce5d27717cb",
       "contentIndex":0,
       "messageStatus":{
          "timestamp":"2024-03-29 07:55:58 pm",
          "code":"REJECTED",
          "description":"The message was rejected by the provider"
       }
    }
  }
=end

=begin
{
   "type":"MESSAGE",
   "id":"9a643fde-7081-48cb-b2f2-14ddfb64cee9",
   "timestamp":"2024-03-29 10:38:07 pm",
   "subscriptionId":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
   "channel":"facebook",
   "direction":"IN",
   "message":{
      "id":"9a643fde-7081-48cb-b2f2-14ddfb64cee9",
      "from":"7136628119690362",
      "to":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
      "direction":"IN",
      "channel":"facebook",
      "visitor":{
         "name":"Clairton Rodrigo Heinzen",
         "firstName":"Clairton Rodrigo",
         "lastName":"Heinzen",
         "picture":"https://platform-lookaside.fbsbx.com/platform/profilepic/?eai=AXEMHxV_i8n2M787_v-PphBIRvN70e50_ZaJaygq0OQNIPH7-sfrUhrglqdj5eLWYJ23wF8DG84M&psid=7136628119690362&width=1024&ext=1714343887&hash=AfplUu_FmSY14ettnD4O4XLRtMcAv7jy3Qp7ZQWQJLvZCw"
      },
      "contents":[
         {
            "type":"text",
            "text":"teste"
         }
      ],
      "timestamp":"2024-03-29 10:38:07 pm"
   },
   "hub_access_token":"f20018fa-eb17-11ee-880c-0efa6ad28f4f.a852adee-f1f4-440e-9443-9ec21b0b3ed5",
   "controller":"webhooks/notifica_me",
   "action":"process_payload",
   "channel_id":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
   "notifica_me":{
      "type":"MESSAGE",
      "id":"9a643fde-7081-48cb-b2f2-14ddfb64cee9",
      "timestamp":"2024-03-29 10:38:07 pm",
      "subscriptionId":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
      "channel":"facebook",
      "direction":"IN",
      "message":{
         "id":"9a643fde-7081-48cb-b2f2-14ddfb64cee9",
         "from":"7136628119690362",
         "to":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
         "direction":"IN",
         "channel":"facebook",
         "visitor":{
            "name":"Clairton Rodrigo Heinzen",
            "firstName":"Clairton Rodrigo",
            "lastName":"Heinzen",
            "picture":"https://platform-lookaside.fbsbx.com/platform/profilepic/?eai=AXEMHxV_i8n2M787_v-PphBIRvN70e50_ZaJaygq0OQNIPH7-sfrUhrglqdj5eLWYJ23wF8DG84M&psid=7136628119690362&width=1024&ext=1714343887&hash=AfplUu_FmSY14ettnD4O4XLRtMcAv7jy3Qp7ZQWQJLvZCw"
         },
         "contents":[
            {
               "type":"text",
               "text":"teste"
            }
         ],
         "timestamp":"2024-03-29 10:38:07 pm"
      }
   }
}
=end


=begin
{
   "type":"MESSAGE_STATUS",
   "timestamp":"2024-03-29 11:40:01 pm",
   "subscriptionId":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
   "channel":"facebook",
   "messageId":"0550ff2d-62f1-45e7-bbf6-fb7b33bb6f80",
   "contentIndex":0,
   "messageStatus":{
      "timestamp":"2024-03-29 11:40:01 pm",
      "code":"SENT",
      "description":"The message has been forwarded to the provider"
   },
   "hub_access_token":"f20018fa-eb17-11ee-880c-0efa6ad28f4f.a852adee-f1f4-440e-9443-9ec21b0b3ed5",
   "controller":"webhooks/notifica_me",
   "action":"process_payload",
   "channel_id":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
   "notifica_me":{
      "type":"MESSAGE_STATUS",
      "timestamp":"2024-03-29 11:40:01 pm",
      "subscriptionId":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
      "channel":"facebook",
      "messageId":"0550ff2d-62f1-45e7-bbf6-fb7b33bb6f80",
      "contentIndex":0,
      "messageStatus":{
         "timestamp":"2024-03-29 11:40:01 pm",
         "code":"SENT",
         "description":"The message has been forwarded to the provider"
      }
   },
   "retried":true
}
=end

  def perform(params = {})
    Rails.logger.error("NotificaMe params webhook #{params}")
    channel = Channel::NotificaMe.find_by(notifica_me_id: params['channel_id'])
    unless channel
      Rails.logger.warn("NotificaMe Channel #{params['channel_id']} not found")
      return
    end

    process_event_params(channel, params)
  end

  private

  def process_event_params(channel, params)
    if params['type'] == 'MESSAGE_STATUS'
      message = Message.find_by(source_id: params['messageId'])
      unless message
        unless params['retried']
          Rails.logger.warn("NotificaMe Message source id #{params['messageId']} not found try again")
          params['retried'] = true
          Webhooks::NotificaMeEventsJob.set(wait: 10.seconds).perform_later(params)
        else
          Rails.logger.warn("NotificaMe Message source id #{params['messageId']} not found")
        end
        return
      end
      index = Message.statuses[message.status]
      if params['messageStatus']['code'] == 'REJECTED'
        message.update!(status: :failed, external_error: params['messageStatus']['description'])
      elsif params['messageStatus']['code'] == 'SENT'
        message.update!(status: :sent) if index < Message.statuses[:sent] || message.status == :failed
      elsif params['messageStatus']['code'] == 'DELIVERED'
        message.update!(status: :delivered) if index < Message.statuses[:delivered] || message.status == :failed
      end
    elsif params['type'] == 'MESSAGE'
      return if  params['direction']  == 'OUT'

      message = params['message']
      visitor = message['visitor']
      contact_inbox = ::ContactInboxWithContactBuilder.new(
        source_id: message['from'],
        inbox: channel.inbox,
        contact_attributes: {
          phone_number: visitor[:phone_number],
          email: visitor[:email],
          name: visitor[:name],
          avatar_url: visitor[:picture]
        }
      ).perform

      timestamp = message[:timestamp] ? message[:timestamp].to_i : Time.now.to_i
      conversation = find_or_create_conversation(contact_inbox)

      ActiveRecord::Base.transaction do
        ms = message["contents"].map { |c|
          conversation.messages.create!(
            content: c[c["type"]],
            account_id: contact_inbox.inbox.account_id,
            inbox_id: contact_inbox.inbox.id,
            message_type: :incoming,
            content_type: message_type(c),
            sender: contact_inbox.contact,
            source_id: message['id'],
            status: :progress,
            # created_at: Time.at(message['timestamp'], in: 'UTC')
          )
        }
        Rails.logger.error("messages: #{ms}")
        ms
      rescue StandardError => e
        Rails.logger.error("NotificaMe channel create message error#{e}, #{e.backtrace}")
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def message_type(content)
    content["type"]
  end


  def find_or_create_conversation(contact_inbox)
    conversation = nil
    if contact_inbox.inbox.lock_to_single_conversation
      conversation = contact_inbox.conversations.last
    else
      conversation = contact_inbox.conversations.where.not(status: :resolved).last
    end

    return conversation || ::Conversation.create!(
      {
        account_id: contact_inbox.inbox.account_id,
        inbox_id: contact_inbox.inbox.id,
        contact_id: contact_inbox.contact.id,
        contact_inbox_id: contact_inbox.id
      }
    )
  end
end

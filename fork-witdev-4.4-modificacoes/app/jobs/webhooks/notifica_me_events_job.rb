class Webhooks::NotificaMeEventsJob < ApplicationJob
  include ::FileTypeHelper
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


=begin
{
   "type":"MESSAGE",
   "id":"b35acb2b-f514-4265-bbeb-2c7b6a067317",
   "timestamp":"2024-03-30 11:45:31 am",
   "subscriptionId":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
   "channel":"facebook",
   "direction":"IN",
   "message":{
      "id":"b35acb2b-f514-4265-bbeb-2c7b6a067317",
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
            "type":"file",
            "fileUrl":"https://cdn.fbsbx.com/v/t59.2708-21/434485005_930612625522428_5224348991750059641_n.pdf/ACFrOgBpkv2Rqm98YhldLaIfNbg45BYfTLeGSZtJLjOXbs0VB0pZImxnSOykt_yGe_GV8fDeOa1rDvDy9bxB32beMOBiQjcFFWHEGj0rqfCVK6RkKUdKFZ2EehpJGKf18fWyornPsoJo1-lnpFPH.pdf?_nc_cat=101&ccb=1-7&_nc_sid=2b0e22&_nc_ohc=rsmp8Hn2sogAX-QUEHb&_nc_ht=cdn.fbsbx.com&oh=03_AdR6tStc0_BdouhOMftMaz7QOOWYkdOKcvQw8OuAmRAg-A&oe=6609BE0E",
            "fileMimeType":"application/pdf",
            "fileName":"ACFrOgBpkv2Rqm98YhldLaIfNbg45BYfTLeGSZtJLjOXbs0VB0pZImxnSOykt_yGe_GV8fDeOa1rDvDy9bxB32beMOBiQjcFFWHEGj0rqfCVK6RkKUdKFZ2EehpJGKf18fWyornPsoJo1-lnpFPH.pdf"
         }
      ],
      "timestamp":"2024-03-30 11:45:31 am"
   },
   "hub_access_token":"f20018fa-eb17-11ee-880c-0efa6ad28f4f.a852adee-f1f4-440e-9443-9ec21b0b3ed5",
   "controller":"webhooks/notifica_me",
   "action":"process_payload",
   "channel_id":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
   "notifica_me":{
      "type":"MESSAGE",
      "id":"b35acb2b-f514-4265-bbeb-2c7b6a067317",
      "timestamp":"2024-03-30 11:45:31 am",
      "subscriptionId":"a852adee-f1f4-440e-9443-9ec21b0b3ed5",
      "channel":"facebook",
      "direction":"IN",
      "message":{
         "id":"b35acb2b-f514-4265-bbeb-2c7b6a067317",
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
               "type":"file",
               "fileUrl":"https://cdn.fbsbx.com/v/t59.2708-21/434485005_930612625522428_5224348991750059641_n.pdf/ACFrOgBpkv2Rqm98YhldLaIfNbg45BYfTLeGSZtJLjOXbs0VB0pZImxnSOykt_yGe_GV8fDeOa1rDvDy9bxB32beMOBiQjcFFWHEGj0rqfCVK6RkKUdKFZ2EehpJGKf18fWyornPsoJo1-lnpFPH.pdf?_nc_cat=101&ccb=1-7&_nc_sid=2b0e22&_nc_ohc=rsmp8Hn2sogAX-QUEHb&_nc_ht=cdn.fbsbx.com&oh=03_AdR6tStc0_BdouhOMftMaz7QOOWYkdOKcvQw8OuAmRAg-A&oe=6609BE0E",
               "fileMimeType":"application/pdf",
               "fileName":"ACFrOgBpkv2Rqm98YhldLaIfNbg45BYfTLeGSZtJLjOXbs0VB0pZImxnSOykt_yGe_GV8fDeOa1rDvDy9bxB32beMOBiQjcFFWHEGj0rqfCVK6RkKUdKFZ2EehpJGKf18fWyornPsoJo1-lnpFPH.pdf"
            }
         ],
         "timestamp":"2024-03-30 11:45:31 am"
      }
   }
}
=end

=begin
{
   "type":"MESSAGE",
   "id":"66ba7478-9a4b-445e-8586-8e5e8ca848b4",
   "timestamp":"2024-04-10 06:44:39 pm",
   "subscriptionId":"b9fc5428-a397-44f1-9826-18097000e6e8",
   "channel":"telegram",
   "direction":"IN",
   "message":{
      "id":"66ba7478-9a4b-445e-8586-8e5e8ca848b4",
      "from":"6917951225",
      "to":"b9fc5428-a397-44f1-9826-18097000e6e8",
      "direction":"IN",
      "channel":"telegram",
      "visitor":{
         "name":"Silvia Heinzen",
         "firstName":"Silvia",
         "lastName":"Heinzen",
         "picture":""
      },
      "group":{
         "id":"",
         "name":""
      },
      "isGroup":"false",
      "contents":[
         {
            "type":"text",
            "text":"Oi"
         }
      ],
      "timestamp":"2024-04-10 06:44:39 pm"
   },
   "hub_access_token":"f20018fa-eb17-11ee-880c-0efa6ad28f4f.b9fc5428-a397-44f1-9826-18097000e6e8",
   "controller":"webhooks/notifica_me",
   "action":"process_payload",
   "channel_id":"b9fc5428-a397-44f1-9826-18097000e6e8",
   "notifica_me":{
      "type":"MESSAGE",
      "id":"66ba7478-9a4b-445e-8586-8e5e8ca848b4",
      "timestamp":"2024-04-10 06:44:39 pm",
      "subscriptionId":"b9fc5428-a397-44f1-9826-18097000e6e8",
      "channel":"telegram",
      "direction":"IN",
      "message":{
         "id":"66ba7478-9a4b-445e-8586-8e5e8ca848b4",
         "from":"6917951225",
         "to":"b9fc5428-a397-44f1-9826-18097000e6e8",
         "direction":"IN",
         "channel":"telegram",
         "visitor":{
            "name":"Silvia Heinzen",
            "firstName":"Silvia",
            "lastName":"Heinzen",
            "picture":""
         },
         "group":{
            "id":"",
            "name":""
         },
         "isGroup":"false",
         "contents":[
            {
               "type":"text",
               "text":"Oi"
            }
         ],
         "timestamp":"2024-04-10 06:44:39 pm"
      }
   }
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
      messageStatus = params['messageStatus']['code']
      messageProviderId = params['messageStatus']['providerMessageId']
      messageId = params['messageId']
      source_id = ['SENT', 'REJECTED', 'ERROR'].include?(messageStatus) ? messageId : messageProviderId
      Rails.logger.warn("NotificaMe Message source id #{source_id} for status #{messageStatus}")
      message = Message.find_by(source_id: source_id)
      unless message
        unless params['retried']
          Rails.logger.warn("NotificaMe Message source id #{source_id} not found try again")
          params['retried'] = true
          time = messageStatus == 'SENT' ? 3 : 5
          Webhooks::NotificaMeEventsJob.set(wait: time.seconds).perform_later(params)
        else
          Rails.logger.warn("NotificaMe Message source id #{source_id} not found")
        end
        return
      end
      index = Message.statuses[message.status]
      if ['ERROR', 'REJECTED'].include?(messageStatus)
        Rails.logger.warn("NotificaMe Message source id #{source_id} update to failed")
        error = (params['messageStatus']['error'] && params['messageStatus']['error']['message']) || params['messageStatus']['description']
        message.update!(status: :failed, external_error: error)
      elsif messageStatus == 'SENT'
        Rails.logger.info("NotificaMe Message source id #{source_id} update to sent current index #{index} compare #{Message.statuses[:sent]}")
        attrs = { status: :sent }
        attrs[:source_id] = messageProviderId if messageProviderId
        message.update!(attrs) if index < Message.statuses[:sent] || message.status == :failed
      elsif messageStatus == 'DELIVERED'
        Rails.logger.info("NotificaMe Message source id #{source_id} update to delivered current index #{index} compare #{Message.statuses[:delivered]}")
        message.update!(status: :delivered) if index < Message.statuses[:delivered] || message.status == :failed
      elsif messageStatus == 'READ'
         Rails.logger.info("NotificaMe Message source id #{source_id} update to read current index #{index} compare #{Message.statuses[:read]}")
        message.update!(status: :read) if index < Message.statuses[:read] || message.status == :failed
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
        ms = message['contents'].map { |c|
          content = c[c['type']] || ''
          m = conversation.messages.build(
            content: content,
            account_id: contact_inbox.inbox.account_id,
            inbox_id: contact_inbox.inbox.id,
            message_type: :incoming,
            content_type: :text,
            sender: contact_inbox.contact,
            source_id: message['id'],
            # status: :progress,
            # created_at: Time.at(message['timestamp'], in: 'UTC')
          )

          if c['type'] != 'text'
            Rails.logger.error("channel.notifica_me_type #{channel.notifica_me_type}")
            attachment_file = if channel.notifica_me_type == 'whatsapp_business_account'
               body = {
                  from: params['channel_id'],
                  contents: [{
                     type: c['type'],
                     fileMimeType: c['fileMimeType'],
                     fileUrl: c['fileUrl']
                  }]
               }.to_json
               url = "https://hub.notificame.com.br/v1/channels/whatsapp/media"
               Rails.logger.error("Download #{url} => #{body}")
               headers = {
                  'X-API-Token' => channel.notifica_me_token,
                  'Content-Type' => 'application/json'
               }
               # response = HTTParty.post(
               #    url,
               #    body: ,
               #    headers: {
               #       'X-API-Token' => channel.notifica_me_token,
               #       'Content-Type' => 'application/json'
               #    }, 
               #    stream_body: true,
               # )
               # # Rails.logger.error("response #{response}")
               # io = StringIO.new(response.body)
               # Rails.logger.error("io #{io}")
               content = Down.download(url, method: :post, body: body, headers: headers)
               Rails.logger.error("content #{content}")
               content.read
            else
               Down.download(c['fileUrl'])
            end
            return if attachment_file.blank?
            a = m.attachments.new(
              account_id: contact_inbox.inbox.account_id,
              file_type: file_type(c['fileMimeType']),
              file: {
                io: attachment_file,
                filename: c['fileName'],
                content_type: c['fileMimeType']
              }
            )
            a.save!
          end
          m.save!
          m
        }
        ms
      rescue StandardError => e
        Rails.logger.error("NotificaMe channel create message error#{e}, #{e.backtrace}")
        raise ActiveRecord::Rollback
      end
    end
  end

  private

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

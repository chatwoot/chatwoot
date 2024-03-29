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

  def perform(params = {})
    channel = Channel::NotificaMe.find_by(channel_id: params['channel_id'])
    unless channel
      Rails.logger.warn("NotificaMe Channel #{params['channel_id']} not found")
      return
    end

    process_event_params(channel, params)
  end

  private

  def process_event_params(channel, params)
    if params['type'] == 'MESSAGE_STATUS'
      message = Message.last #find_by(source_id: params['messageId'])
      unless message
        Rails.logger.warn("NotificaMe Message source id #{params['messageId']} not found")
        return
      end

      if params['messageStatus']['code'] == 'REJECTED'
        message.update!(status: :failed, external_error: params['messageStatus']['description'])
      end
    end
  end
end

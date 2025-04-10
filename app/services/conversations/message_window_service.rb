class Conversations::MessageWindowService
    def initialize(conversation)
      @conversation = conversation
    end
  
    def can_reply?
      return true if messaging_window.blank?
  
      last_message_in_messaging_window?(messaging_window)
    end
  
    private
  
    def messaging_window
      case @conversation.inbox.channel_type
      when 'Channel::Api'
        if @conversation.inbox.channel.additional_attributes['agent_reply_time_window'].present?
          @conversation.inbox.channel.additional_attributes['agent_reply_time_window'].to_i.hours
        end
      when 'Channel::FacebookPage'
        messenger_messaging_window
      when 'Channel::Instagram'
        instagram_messaging_window
      when 'Channel::Whatsapp'
        24.hours
      end
    end
  
    def last_message_in_messaging_window?(time)
      return false if last_incoming_message.nil?
  
      Time.current < last_incoming_message.created_at + time
    end
  
    def messenger_messaging_window
      global_config = GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')
  
      if global_config['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT']
        7.days
      else
        24.hours
      end
    end
  
    def instagram_messaging_window
      global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
  
      if global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']
        7.days
      else
        24.hours
      end
    end
  
    def last_incoming_message
      @conversation.messages&.incoming&.last
    end
  end
  
module Voice
  class RecordingService
    pattr_initialize [:conversation!, :recording_url!, :recording_sid!, :call_sid]

    def process
      # Skip if already processed
      return if recording_already_processed?
      
      # Create message from the recording
      message = create_recording_message
      
      # Download and attach the recording
      attach_recording_to_message(message)
      
      message
    end
    
    private
    
    def recording_already_processed?
      conversation.messages.where('additional_attributes @> ?', { recording_sid: recording_sid }.to_json).exists?
    end
    
    def create_recording_message
      contact = conversation.contact
      return nil unless contact
      
      message_params = {
        content: 'Voice Recording',
        message_type: :incoming,
        additional_attributes: {
          call_sid: call_sid,
          recording_url: recording_url,
          recording_sid: recording_sid
        }
      }
      
      Messages::MessageBuilder.new(contact, conversation, message_params).perform
    end
    
    def attach_recording_to_message(message)
      return unless message && valid_recording_url?
      
      begin
        # Get authentication details from the inbox channel
        config = conversation.inbox.channel.provider_config_hash
        account_sid = config['account_sid']
        auth_token = config['auth_token']
        
        # Download the MP3 version of the recording
        recording_mp3_url = "#{recording_url}.mp3"
        download_file = Down.download(
          recording_mp3_url,
          http_basic_authentication: [account_sid, auth_token]
        )
        
        # Create the attachment
        attachment = message.attachments.new(
          file_type: :audio,
          account_id: conversation.account_id,
          extension: 'mp3',
          fallback_title: 'Voice Recording',
          meta: {
            recording_sid: recording_sid,
            twilio_account_sid: account_sid,
            auth_required: true
          }
        )
        
        # Attach the file
        attachment.file.attach(
          io: download_file,
          filename: "#{recording_sid}.mp3",
          content_type: 'audio/mpeg'
        )
        
        attachment.save!
      rescue StandardError => e
        Rails.logger.error("Error attaching recording: #{e.message}")
      end
    end
    
    def valid_recording_url?
      # Validate that the URL is a proper Twilio recording URL
      uri = URI.parse(recording_url)
      return false unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      
      recording_url.include?('/Recordings/') && recording_sid.present?
    end
  end
end
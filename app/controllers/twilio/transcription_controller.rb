class Twilio::TranscriptionController < ActionController::Base
  skip_forgery_protection

  # Receives real-time transcription updates from Twilio
  def transcription_callback
    # Set Current.account
    Current.account = Account.find_by(id: params[:account_id])
    
    # Only process transcription content events
    if params['TranscriptionEvent'] == 'transcription-content'
      process_transcription_content
    end

    head :ok
  end

  private

  def process_transcription_content
    # Extract transcript content from JSON
    data = JSON.parse(params['TranscriptionData'])
    transcript_content = data['transcript']
    confidence = data['confidence']
  
    
    # Find conversation by conference_sid from our standard format
    display_id = params[:conference_sid].match(/^conf_account_\d+_conv_(\d+)$/)[1]
    conversation = Current.account.conversations.find_by(display_id: display_id)
    
    # Create message based on speaker_type
    create_message(conversation, transcript_content, confidence)
  end
  
  def create_message(conversation, content, confidence)
    if params[:speaker_type] == 'contact'
      # Contact message (incoming)
      sender = conversation.contact
      message_type = :incoming
    else
      # Agent message (outgoing)
      sender = User.find_by(id: params[:agent_id])
      message_type = :outgoing
    end
    
    # Create the message
    Messages::MessageBuilder.new(
      sender,
      conversation,
      content: content,
      message_type: message_type,
      private: false,
      additional_attributes: {
        transcription: true,
        call_sid: params['CallSid'],
        conference_sid: params[:conference_sid],
        speaker_type: params[:speaker_type],
        confidence: confidence,
        track: params['Track']
      }
    ).perform
  end
end
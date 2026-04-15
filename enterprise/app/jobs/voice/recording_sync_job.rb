class Voice::RecordingSyncJob < ApplicationJob
  queue_as :low

  def perform(account_id:, call_sid:, recording_url:, recording_sid:)
    @account = Account.find(account_id)
    @call_sid = call_sid
    @recording_url = recording_url
    @recording_sid = recording_sid

    return if @recording_url.blank?

    @message = find_message
    return if @message.nil?

    attach_recording
  end

  private

  def find_message
    # Find the message associated with this CallSid
    # We look for voice_call messages where the call_sid matches in content_attributes
    message = @account.messages
                      .where(content_type: :voice_call)
                      .where("content_attributes->'data'->>'call_sid' = ?", @call_sid)
                      .order(created_at: :desc)
                      .first

    return message if message.present?

    # Fallback search for cases where JSON columns are not queryable directly or double-serialized
    # Looking back 1 day to keep performance reasonable
    @account.messages.voice_calls.where("created_at >= ?", 1.day.ago).order(created_at: :desc).find do |msg|
      data = msg.content_attributes['data']
      # Handle potential stringification
      data = JSON.parse(data) if data.is_a?(String)
      data && data.is_a?(Hash) && data['call_sid'] == @call_sid
    end
  end

  def attach_recording
    # Download the audio file from Twilio
    # Twilio recording URLs usually need .mp3 or .wav appended if not present
    download_url = @recording_url.end_with?('.mp3') ? @recording_url : "#{@recording_url}.mp3"
    
    begin
      file = Down.download(download_url)
      
      @message.attachments.create!(
        account_id: @account.id,
        file_type: :audio,
        file: {
          io: file,
          filename: "recording_#{@recording_sid}.mp3",
          content_type: 'audio/mpeg'
        }
      )
      
      # Update message to indicate recording is available
      data = @message.content_attributes['data'] || {}
      data['recording_sid'] = @recording_sid
      data['recording_url'] = @recording_url
      @message.update!(content_attributes: @message.content_attributes.merge('data' => data))
      
    rescue StandardError => e
      Rails.logger.error "[Voice::RecordingSyncJob] Failed to sync recording for call_sid #{@call_sid}: #{e.message}"
    end
  end
end

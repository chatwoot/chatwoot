namespace :audio_transcription do
  desc 'Cleanup stuck audio transcription messages'
  task cleanup_stuck_messages: :environment do
    puts 'Starting cleanup of stuck audio transcription messages...'

    # Find messages with audio attachments created more than 5 minutes ago
    # that don't have transcription metadata (stuck in "Transcribing..." state)
    stuck_message_ids = Attachment.where(file_type: :audio)
                                   .joins(:message)
                                   .where('messages.created_at < ?', 5.minutes.ago)
                                   .where("messages.content_attributes->>'transcription' IS NULL")
                                   .pluck(Arel.sql('DISTINCT messages.id'))

    count = stuck_message_ids.count
    puts "Found #{count} stuck messages with audio attachments"

    if count.zero?
      puts 'No stuck messages found'
      next
    end

    # Mark each stuck message as failed
    Message.where(id: stuck_message_ids).find_each do |message|
      attrs = message.content_attributes || {}
      attrs['transcription'] = {
        'error' => 'Transcription timeout or processing error',
        'failed_at' => Time.current.iso8601
      }

      message.update!(content_attributes: attrs)
      puts "Marked message #{message.id} as failed (conversation: #{message.conversation_id})"

      # Broadcast update to frontend if conversation is active
      begin
        ActionCable.server.broadcast(
          "messages:#{message.conversation_id}",
          {
            event: 'message.updated',
            data: message.push_event_data
          }
        )
      rescue StandardError => e
        puts "Warning: Could not broadcast update for message #{message.id}: #{e.message}"
      end
    end

    puts "Successfully marked #{count} stuck messages as failed"
    puts 'Cleanup complete!'
  end

  desc 'Retry failed audio transcriptions'
  task retry_failed: :environment do
    puts 'Starting retry of failed audio transcriptions...'

    # Find messages with failed transcriptions
    failed_message_ids = Attachment.where(file_type: :audio)
                                    .joins(:message)
                                    .where("messages.content_attributes->>'transcription' IS NOT NULL")
                                    .where("messages.content_attributes->'transcription'->>'error' IS NOT NULL")
                                    .pluck(Arel.sql('DISTINCT messages.id'))

    count = failed_message_ids.count
    puts "Found #{count} messages with failed transcriptions"

    if count.zero?
      puts 'No failed transcriptions found'
      next
    end

    # Retry each failed message
    Message.where(id: failed_message_ids).find_each do |message|
      # Clear transcription metadata
      attrs = message.content_attributes || {}
      attrs.delete('transcription')
      message.update!(content_attributes: attrs)

      # Re-enqueue transcription jobs
      message.attachments.where(file_type: :audio).each do |attachment|
        TranscribeAudioMessageJob.perform_later(message.id, attachment.id)
        puts "Re-enqueued transcription for message #{message.id}, attachment #{attachment.id}"
      end
    end

    puts "Successfully re-enqueued #{count} failed transcriptions"
    puts 'Retry complete!'
  end
end

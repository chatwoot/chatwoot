# frozen_string_literal: true

module Aloo
  class VoiceReplyJob < ApplicationJob
    queue_as :default
    retry_on Aloo::ElevenlabsClient::Error, wait: :polynomially_longer, attempts: 3
    retry_on StandardError, wait: :polynomially_longer, attempts: 2

    def perform(message_id)
      @message = Message.find_by(id: message_id)
      return unless @message

      @conversation = @message.conversation
      @assistant = @conversation.inbox.aloo_assistant

      return unless should_generate_voice?

      generate_and_send_voice
    rescue StandardError => e
      Rails.logger.error("[Aloo::VoiceReplyJob] Error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      raise
    end

    private

    def should_generate_voice?
      return false unless @assistant&.voice_reply_enabled?

      # Only process outgoing messages from the assistant
      return false unless @message.outgoing?
      return false if @message.content.blank?

      # Skip if already has audio attachment
      return false if @message.attachments.exists?(file_type: 'audio')

      # Check reply mode
      reply_mode = @assistant.effective_reply_mode
      %w[voice_only text_and_voice].include?(reply_mode)
    end

    def generate_and_send_voice
      # Generate voice using synthesis service
      result = Aloo::VoiceSynthesisService.new(
        text: @message.content,
        assistant: @assistant,
        message: @message
      ).perform

      unless result[:success]
        Rails.logger.warn("[Aloo::VoiceReplyJob] Synthesis failed: #{result[:error]}")
        return
      end

      # Handle based on reply mode
      reply_mode = @assistant.effective_reply_mode

      case reply_mode
      when 'voice_only'
        # Create a new message with only audio
        create_voice_only_message(result)
      when 'text_and_voice'
        # Add audio attachment to existing message
        attach_audio_to_message(result)
        send_to_channel(@message)
      end
    ensure
      # Clean up temp file
      cleanup_temp_file(result[:audio_path]) if result&.dig(:audio_path)
    end

    def create_voice_only_message(result)
      # For voice-only mode, we create a separate audio message
      audio_message = ::Messages::MessageBuilder.new(
        @assistant,
        @conversation,
        { content: '', message_type: :outgoing, private: false }
      ).perform

      return unless audio_message.persisted?

      attach_audio_to_message(result, audio_message)
      send_to_channel(audio_message)
    end

    def attach_audio_to_message(result, message = @message)
      audio_path = result[:audio_path]
      return unless audio_path && File.exist?(audio_path)

      File.open(audio_path, 'rb') do |audio_file|
        message.attachments.create!(
          account_id: message.account_id,
          file_type: :audio,
          file: {
            io: audio_file,
            filename: "voice_reply_#{Time.current.to_i}.ogg",
            content_type: 'audio/ogg'
          }
        )
      end

      Rails.logger.info("[Aloo::VoiceReplyJob] Audio attached to message #{message.id}")
    end

    def send_to_channel(message)
      inbox = @conversation.inbox

      case inbox.channel_type
      when 'Channel::Whatsapp'
        Whatsapp::SendOnWhatsappService.new(message: message).perform
      when 'Channel::FacebookPage'
        Facebook::SendOnFacebookService.new(message: message).perform
      when 'Channel::Telegram'
        ::SendReplyJob.perform_later(message.id)
      else
        # For API channels and web widget, message is already saved
        # WebSocket will handle delivery
        Rails.logger.info("[Aloo::VoiceReplyJob] Message #{message.id} saved for #{inbox.channel_type}")
      end
    end

    def cleanup_temp_file(path)
      return unless path && File.exist?(path)

      File.delete(path)
      Rails.logger.debug { "[Aloo::VoiceReplyJob] Cleaned up temp file: #{path}" }
    rescue Errno::ENOENT
      # File already deleted, ignore
    end
  end
end

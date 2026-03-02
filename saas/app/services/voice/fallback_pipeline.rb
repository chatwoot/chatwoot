# frozen_string_literal: true

# Fallback voice pipeline for non-realtime flows:
#   1. STT → transcribe audio to text (via provider)
#   2. Text agent (Agent::Executor) → generate a reply
#   3. TTS → synthesize the reply as audio (via provider)
#
# Provider-agnostic: uses Voice::Provider::Base#transcribe and #synthesize.
module Voice
  class FallbackPipeline
    def initialize(ai_agent:, conversation: nil, api_key: nil)
      @ai_agent = ai_agent
      @conversation = conversation
      @api_key = api_key
      @provider = Voice::Provider.for(ai_agent: ai_agent, conversation: conversation, api_key: api_key)
    end

    # Transcribe audio to text
    def transcribe(audio_file_path:, language: nil)
      @provider.transcribe(audio_file_path: audio_file_path, language: language)
    end

    # Synthesize text to speech
    def synthesize(text, **options)
      @provider.synthesize(text, **options)
    end

    # Full pipeline: audio → text → agent reply → audio
    # Returns { transcript:, reply_text:, audio_base64:, handed_off: }
    def process(audio_file_path:, conversation_history: [], language: nil)
      # Step 1: STT
      transcript = transcribe(audio_file_path: audio_file_path, language: language)
      return { transcript: nil, reply_text: 'Could not transcribe audio.', audio_base64: nil } if transcript.blank?

      # Save user transcript
      save_message(transcript, message_type: :incoming, attrs: { voice_transcription: true }) if @conversation

      # Step 2: Text agent
      executor = Agent::Executor.new(ai_agent: @ai_agent, conversation: @conversation, api_key: @api_key)
      result = executor.execute(user_message: transcript, conversation_history: conversation_history)

      # Save agent reply
      if @conversation && !result.handed_off?
        save_message(result.reply, message_type: :outgoing, attrs: { ai_generated: true, voice: true })
      end

      # Step 3: TTS
      audio_base64 = synthesize(result.reply) unless result.handed_off?

      {
        transcript: transcript,
        reply_text: result.reply,
        audio_base64: audio_base64,
        handed_off: result.handed_off?
      }
    end

    private

    def save_message(content, message_type:, attrs: {})
      @conversation.messages.create!(
        content: content,
        message_type: message_type,
        account_id: @conversation.account_id,
        inbox_id: @conversation.inbox_id,
        content_attributes: attrs.merge(ai_agent_id: @ai_agent.id)
      )
    end
  end
end

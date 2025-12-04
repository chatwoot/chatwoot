# frozen_string_literal: true

# Abstract base class for LLM provider implementations.
# All providers must implement the methods defined here to ensure compatibility
# with the existing services.
class Captain::Service
  # Initialize the provider with configuration
  def initialize
    @config = Captain::Config.config_for(Captain::Config.current_provider)
    initialize_client
  end

  # ============================================================================
  # EMBEDDINGS
  # ============================================================================
  # Converts text into vector representations for semantic search.
  #
  # @param parameters [Hash] The embedding parameters
  # @option parameters [String] :model The embedding model name (e.g., "text-embedding-3-small")
  # @option parameters [String] :input The text content to embed
  #
  # @return [Hash] Response with structure:
  #   {
  #     "data" => [
  #       {
  #         "embedding" => Array<Float>  # Vector of floating point numbers
  #       }
  #     ]
  #   }
  def embeddings(parameters:)
    raise NotImplementedError, "#{self.class} must implement #embeddings"
  end

  # ============================================================================
  # AUDIO TRANSCRIPTION
  # ============================================================================
  # Converts audio files to text.
  #
  # @param parameters [Hash] The transcription parameters
  # @option parameters [String] :model The transcription model name (e.g., "whisper-1")
  # @option parameters [File] :file The audio file object
  # @option parameters [Float] :temperature Optional temperature parameter
  #
  # @return [Hash] Response with structure:
  #   {
  #     "text" => String  # The transcribed text
  #   }
  def transcribe(parameters:)
    raise NotImplementedError, "#{self.class} must implement #transcribe"
  end

  # ============================================================================
  # FILE UPLOAD
  # ============================================================================
  # Uploads files (e.g., PDFs) to the LLM provider for processing.
  #
  # @param parameters [Hash] The upload parameters
  # @option parameters [File] :file The file object to upload
  # @option parameters [String] :purpose The purpose of the upload (e.g., "assistants")
  #
  # @return [Hash] Response with structure:
  #   {
  #     "id" => String  # File identifier, e.g., "file-xyz123"
  #   }
  def upload_file(parameters:)
    raise NotImplementedError, "#{self.class} must implement #upload_file"
  end

  # ============================================================================
  # CHAT COMPLETION
  # ============================================================================
  # Generates responses from conversational prompts.
  # Supports both JSON mode and conversational mode with optional tool calling.
  #
  # @param parameters [Hash] The chat parameters
  # @option parameters [String] :model The chat model name (e.g., "gpt-4")
  # @option parameters [Array<Hash>] :messages Conversation history
  #   Each message: { role: String, content: String|Array }
  # @option parameters [Hash] :response_format Optional, e.g., { type: 'json_object' }
  # @option parameters [Array<Hash>] :tools Optional tool definitions
  # @option parameters [Float] :temperature Optional temperature parameter
  #
  # @return [Hash] Response with structure:
  #   {
  #     "choices" => [
  #       {
  #         "message" => {
  #           "content" => String,              # Response text
  #           "tool_calls" => Array<Hash>       # Optional tool invocations
  #         }
  #       }
  #     ]
  #   }
  def chat(parameters:)
    raise NotImplementedError, "#{self.class} must implement #chat"
  end

  private

  # Initialize the provider-specific client.
  # Must be implemented by subclasses.
  def initialize_client
    raise NotImplementedError, "#{self.class} must implement #initialize_client"
  end
end

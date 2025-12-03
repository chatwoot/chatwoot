# frozen_string_literal: true

# Abstract base service class for LLM providers
# Each provider implements API calls in their own format
class Captain::Service
  attr_reader :config, :client

  def initialize(config)
    @config = config
    @client = initialize_client
  end

  # Chat completion API call
  # Each provider formats the request/response in their own way
  # @param messages [Array<Hash>] Array of message hashes with role and content
  # @param model [String] Model to use for chat completion
  # @param options [Hash] Additional options (tools, temperature, etc.)
  # @return [Hash] Normalized response hash
  def chat(messages:, model:, **options)
    raise NotImplementedError, "#{self.class.name} must implement #chat"
  end

  # Embeddings API call
  # Each provider formats the request/response in their own way
  # @param input [String, Array<String>] Text to embed
  # @param model [String] Model to use for embeddings
  # @return [Hash] Normalized response hash with embeddings
  def embeddings(input:, model:)
    raise NotImplementedError, "#{self.class.name} must implement #embeddings"
  end

  # Audio transcription API call
  # Each provider formats the request/response in their own way
  # @param file [File, String] Audio file to transcribe
  # @param model [String] Model to use for transcription
  # @return [Hash] Normalized response hash with transcription
  def transcribe(file:, model:)
    raise NotImplementedError, "#{self.class.name} must implement #transcribe"
  end

  # File upload API call
  # Each provider formats the request/response in their own way
  # @param file [File, String] File to upload
  # @param purpose [String] Purpose of the file upload
  # @return [Hash] Normalized response hash with file ID
  def upload_file(file:, purpose:)
    raise NotImplementedError, "#{self.class.name} must implement #upload_file"
  end

  private

  # Initialize the API client
  # Each provider sets up their own client (OpenAI gem, HTTP client, etc.)
  def initialize_client
    raise NotImplementedError, "#{self.class.name} must implement #initialize_client"
  end
end

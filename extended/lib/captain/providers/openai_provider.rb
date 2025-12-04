# frozen_string_literal: true

require_relative 'openai/chat'
require_relative 'openai/embeddings'
require_relative 'openai/transcribe'
require_relative 'openai/upload_file'

class Captain::Providers::OpenaiProvider < Captain::Service
  include Captain::Providers::Openai::Chat
  include Captain::Providers::Openai::Embeddings
  include Captain::Providers::Openai::Transcribe
  include Captain::Providers::Openai::UploadFile

  attr_reader :client, :config

  private

  def initialize_client
    @client = OpenAI::Client.new(
      access_token: @config[:api_key],
      uri_base: @config[:endpoint],
      log_errors: Rails.env.development?
    )
  end

  def handle_error(result)
    error_message = result.dig('error', 'message') || 'Unknown OpenAI error'
    raise StandardError, "OpenAI API Error: #{error_message}"
  end
end

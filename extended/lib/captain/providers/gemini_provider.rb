# frozen_string_literal: true

require_relative 'gemini/chat'
require_relative 'gemini/embeddings'
require_relative 'gemini/transcribe'
require_relative 'gemini/upload_file'

# TODO: Implement Gemini provider using direct HTTP requests
# The gemini-ai gem has issues, so we need to use Faraday directly.
#
# API Base URL: https://generativelanguage.googleapis.com/v1beta
# Authentication: ?key={API_KEY} query parameter
#
# Endpoints:
# - Chat: POST /models/{model}:generateContent
# - Embeddings: POST /models/{model}:embedContent
# - Files: POST /upload/v1beta/files (multipart)
class Captain::Providers::GeminiProvider < Captain::Service
  include Captain::Providers::Gemini::Chat
  include Captain::Providers::Gemini::Embeddings
  include Captain::Providers::Gemini::Transcribe
  include Captain::Providers::Gemini::UploadFile

  attr_reader :client, :config

  private

  def initialize_client
    # TODO: Initialize HTTP client (Faraday) with:
    # - Base URL: https://generativelanguage.googleapis.com/v1beta
    # - API key from @config[:api_key]
    # - Model from @config[:chat_model]
    @client = nil
  end

  def handle_error(error)
    Rails.logger.error "Gemini API Error: #{error.message}"
    raise StandardError, "Gemini API Error: #{error.message}"
  end
end

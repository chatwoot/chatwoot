# frozen_string_literal: true

require 'openai'
require_relative '../service'

# OpenAI provider implementation
# Handles OpenAI-specific client initialization and API calls
class Captain::Providers::OpenaiProvider < Captain::Service
  private

  # Initialize OpenAI client with configuration
  def initialize_client
    OpenAI::Client.new(
      access_token: config[:api_key],
      uri_base: config[:endpoint],
      log_errors: Rails.env.development?
    )
  end

  public

  # Chat completion using OpenAI API
  # Builds complete OpenAI parameters object with all options
  def chat(messages:, model:, **options)
    params = build_chat_parameters(messages, model, options)

    response = @client.chat(parameters: params)
    handle_response(response)
  rescue StandardError => e
    handle_error(e)
  end

  # Embeddings using OpenAI API
  def embeddings(input:, model:)
    params = {
      model: model,
      input: input
    }

    response = @client.embeddings(parameters: params)
    handle_response(response)
  rescue StandardError => e
    handle_error(e)
  end

  # Audio transcription using OpenAI Whisper API
  def transcribe(file:, model:)
    params = {
      model: model,
      file: file
    }

    response = @client.audio.transcribe(parameters: params)
    handle_response(response)
  rescue StandardError => e
    handle_error(e)
  end

  # File upload using OpenAI API
  def upload_file(file:, purpose:)
    params = {
      file: file,
      purpose: purpose
    }

    response = @client.files.upload(parameters: params)
    handle_response(response)
  rescue StandardError => e
    handle_error(e)
  end

  private

  # Build complete OpenAI chat parameters object
  # Includes all OpenAI-specific options
  def build_chat_parameters(messages, model, options)
    params = {
      model: model,
      messages: messages
    }

    add_optional_parameters(params, options)
    params
  end

  # Add optional parameters to chat request
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def add_optional_parameters(params, options)
    params[:tools] = options[:tools] if options[:tools]&.any?
    params[:response_format] = options[:response_format] if options[:response_format]
    params[:temperature] = options[:temperature] if options[:temperature]
    params[:max_tokens] = options[:max_tokens] if options[:max_tokens]
    params[:top_p] = options[:top_p] if options[:top_p]
    params[:frequency_penalty] = options[:frequency_penalty] if options[:frequency_penalty]
    params[:presence_penalty] = options[:presence_penalty] if options[:presence_penalty]
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def handle_response(response)
    response
  end

  def handle_error(error)
    Rails.logger.error("OpenAI API Error: #{error.message}")
    { error: error.message }
  end
end

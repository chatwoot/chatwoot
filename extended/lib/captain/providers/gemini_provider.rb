# frozen_string_literal: true

require 'gemini-ai'
require_relative '../service'

module Captain
  module Providers
    # Gemini provider implementation
    # Handles Gemini-specific client initialization and API calls
    class GeminiProvider < Captain::Service
      private

      # Initialize Gemini client with configuration
      def initialize_client
        Gemini.new(
          credentials: {
            service: 'generative-language-api',
            api_key: config[:api_key]
          },
          options: {
            model: config[:chat_model],
            server_sent_events: true
          }
        )
      end

      public

      # Chat completion using Gemini API
      # Gemini uses different format than OpenAI
      def chat(messages:, model:, **options)
        params = build_chat_parameters(messages, model, options)

        result = @client.stream_generate_content(params)
        handle_chat_response(result)
      rescue StandardError => e
        handle_error(e)
      end

      # Embeddings using Gemini API
      def embeddings(input:, model:)
        # Gemini uses embed-content endpoint
        result = @client.embed_content({
                                         model: "models/#{model}",
                                         content: { parts: [{ text: input }] }
                                       })

        handle_embeddings_response(result)
      rescue StandardError => e
        handle_error(e)
      end

      # Audio transcription using Gemini API
      # Gemini handles audio in multimodal requests
      def transcribe(file:, model:)
        # Gemini processes audio through generate_content with file data
        result = @client.generate_content({
                                            model: "models/#{model}",
                                            contents: {
                                              parts: [
                                                { inline_data: { mime_type: 'audio/wav', data: Base64.encode64(file.read) } }
                                              ]
                                            }
                                          })

        handle_transcription_response(result)
      rescue StandardError => e
        handle_error(e)
      end

      # File upload using Gemini API
      # Gemini uses Files API for large files
      def upload_file(file:, purpose:)
        # Gemini Files API
        result = @client.upload_file({
                                       file: { data: file, mime_type: file.content_type },
                                       display_name: file.original_filename
                                     })

        handle_file_response(result)
      rescue StandardError => e
        handle_error(e)
      end

      private

      # Build Gemini chat parameters
      # Gemini format is different from OpenAI
      def build_chat_parameters(messages, model, options)
        params = {
          model: "models/#{model}",
          contents: format_messages_for_gemini(messages)
        }

        # Add Gemini-specific options
        params[:tools] = format_tools_for_gemini(options[:tools]) if options[:tools]&.any?

        if options[:temperature]
          params[:generation_config] ||= {}
          params[:generation_config][:temperature] = options[:temperature]
        end

        if options[:max_tokens]
          params[:generation_config] ||= {}
          params[:generation_config][:max_output_tokens] = options[:max_tokens]
        end

        params
      end

      # Convert OpenAI message format to Gemini format
      def format_messages_for_gemini(messages)
        messages.map do |msg|
          {
            role: msg[:role] == 'assistant' ? 'model' : 'user',
            parts: [{ text: msg[:content] }]
          }
        end
      end

      # Convert OpenAI tools format to Gemini format
      def format_tools_for_gemini(tools)
        tools.map do |tool|
          {
            function_declarations: [{
              name: tool[:function][:name],
              description: tool[:function][:description],
              parameters: tool[:function][:parameters]
            }]
          }
        end
      end

      def handle_chat_response(result)
        # Extract text from Gemini response
        text = result.dig(0, 'candidates', 0, 'content', 'parts', 0, 'text')
        { choices: [{ message: { content: text } }] }
      end

      def handle_embeddings_response(result)
        # Extract embeddings from Gemini response
        embedding = result.dig('embedding', 'values')
        { data: [{ embedding: embedding }] }
      end

      def handle_transcription_response(result)
        # Extract transcription from Gemini response
        text = result.dig('candidates', 0, 'content', 'parts', 0, 'text')
        { text: text }
      end

      def handle_file_response(result)
        # Extract file info from Gemini response
        { file: { id: result['file']['name'] } }
      end

      def handle_error(error)
        Rails.logger.error("Gemini API Error: #{error.message}")
        { error: error.message }
      end
    end
  end
end

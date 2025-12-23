# frozen_string_literal: true

module RubyLLM
  # Handles streaming responses from AI providers.
  module Streaming
    module_function

    def stream_response(connection, payload, additional_headers = {}, &block)
      accumulator = StreamAccumulator.new

      response = connection.post stream_url, payload do |req|
        req.headers = additional_headers.merge(req.headers) unless additional_headers.empty?
        if faraday_1?
          req.options[:on_data] = handle_stream do |chunk|
            accumulator.add chunk
            block.call chunk
          end
        else
          req.options.on_data = handle_stream do |chunk|
            accumulator.add chunk
            block.call chunk
          end
        end
      end

      message = accumulator.to_message(response)
      RubyLLM.logger.debug "Stream completed: #{message.content}"
      message
    end

    def handle_stream(&block)
      to_json_stream do |data|
        block.call(build_chunk(data)) if data
      end
    end

    private

    def faraday_1?
      Faraday::VERSION.start_with?('1')
    end

    def to_json_stream(&)
      buffer = +''
      parser = EventStreamParser::Parser.new

      create_stream_processor(parser, buffer, &)
    end

    def create_stream_processor(parser, buffer, &)
      if faraday_1?
        legacy_stream_processor(parser, &)
      else
        stream_processor(parser, buffer, &)
      end
    end

    def process_stream_chunk(chunk, parser, env, &)
      RubyLLM.logger.debug "Received chunk: #{chunk}" if RubyLLM.config.log_stream_debug

      if error_chunk?(chunk)
        handle_error_chunk(chunk, env)
      else
        yield handle_sse(chunk, parser, env, &)
      end
    end

    def legacy_stream_processor(parser, &block)
      proc do |chunk, _size|
        process_stream_chunk(chunk, parser, nil, &block)
      end
    end

    def stream_processor(parser, buffer, &block)
      proc do |chunk, _bytes, env|
        if env&.status == 200
          process_stream_chunk(chunk, parser, env, &block)
        else
          handle_failed_response(chunk, buffer, env)
        end
      end
    end

    def error_chunk?(chunk)
      chunk.start_with?('event: error')
    end

    def handle_error_chunk(chunk, env)
      error_data = chunk.split("\n")[1].delete_prefix('data: ')
      status, _message = parse_streaming_error(error_data)
      parsed_data = JSON.parse(error_data)

      error_response = if faraday_1?
                         Struct.new(:body, :status).new(parsed_data, status)
                       else
                         env.merge(body: parsed_data, status: status)
                       end

      ErrorMiddleware.parse_error(provider: self, response: error_response)
    rescue JSON::ParserError => e
      RubyLLM.logger.debug "Failed to parse error chunk: #{e.message}"
    end

    def handle_failed_response(chunk, buffer, env)
      buffer << chunk
      error_data = JSON.parse(buffer)
      error_response = env.merge(body: error_data)
      ErrorMiddleware.parse_error(provider: self, response: error_response)
    rescue JSON::ParserError
      RubyLLM.logger.debug "Accumulating error chunk: #{chunk}"
    end

    def handle_sse(chunk, parser, env, &block)
      parser.feed(chunk) do |type, data|
        case type.to_sym
        when :error
          handle_error_event(data, env)
        else
          yield handle_data(data, &block) unless data == '[DONE]'
        end
      end
    end

    def handle_data(data)
      JSON.parse(data)
    rescue JSON::ParserError => e
      RubyLLM.logger.debug "Failed to parse data chunk: #{e.message}"
    end

    def handle_error_event(data, env)
      status, _message = parse_streaming_error(data)
      parsed_data = JSON.parse(data)

      error_response = if faraday_1?
                         Struct.new(:body, :status).new(parsed_data, status)
                       else
                         env.merge(body: parsed_data, status: status)
                       end

      ErrorMiddleware.parse_error(provider: self, response: error_response)
    rescue JSON::ParserError => e
      RubyLLM.logger.debug "Failed to parse error event: #{e.message}"
    end

    def parse_streaming_error(data)
      error_data = JSON.parse(data)
      [500, error_data['message'] || 'Unknown streaming error']
    rescue JSON::ParserError => e
      RubyLLM.logger.debug "Failed to parse streaming error: #{e.message}"
      [500, "Failed to parse error: #{data}"]
    end
  end
end

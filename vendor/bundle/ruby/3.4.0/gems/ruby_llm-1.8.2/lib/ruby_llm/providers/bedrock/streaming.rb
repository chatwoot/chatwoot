# frozen_string_literal: true

require_relative 'streaming/base'
require_relative 'streaming/content_extraction'
require_relative 'streaming/message_processing'
require_relative 'streaming/payload_processing'
require_relative 'streaming/prelude_handling'

module RubyLLM
  module Providers
    class Bedrock
      # Streaming implementation for the AWS Bedrock API.
      module Streaming
        include Base
      end
    end
  end
end

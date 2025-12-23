# frozen_string_literal: true

module RubyLLM
  module Providers
    class Mistral
      # Chat methods for Mistral API
      module Chat
        module_function

        def format_role(role)
          role.to_s
        end

        # rubocop:disable Metrics/ParameterLists
        def render_payload(messages, tools:, temperature:, model:, stream: false, schema: nil)
          payload = super
          payload.delete(:stream_options)
          payload
        end
        # rubocop:enable Metrics/ParameterLists
      end
    end
  end
end

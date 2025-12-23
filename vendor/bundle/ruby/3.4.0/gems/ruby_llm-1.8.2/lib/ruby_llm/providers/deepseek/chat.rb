# frozen_string_literal: true

module RubyLLM
  module Providers
    class DeepSeek
      # Chat methods of the DeepSeek API integration
      module Chat
        module_function

        def format_role(role)
          role.to_s
        end
      end
    end
  end
end

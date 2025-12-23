# frozen_string_literal: true

module RubyLLM
  module Providers
    class Perplexity
      # Chat formatting for Perplexity provider
      module Chat
        module_function

        def format_role(role)
          role.to_s
        end
      end
    end
  end
end

module Captain
  module Llm
    class FaqGeneratorService
      def initialize(content, language = 'english')
        @content = content
        @language = language
        @llm = Captain::LlmService.new(api_key: ENV.fetch('OPENAI_API_KEY', nil))
      end

      def generate
        messages = [
          { role: 'system', content: Captain::Llm::SystemPromptsService.faq_generator(@language) },
          { role: 'user', content: @content }
        ]

        response = @llm.call(messages, [], json_mode: true)
        parse_result(response[:output])
      rescue StandardError => e
        Rails.logger.error("FaqGeneratorService Error: #{e.message}")
        []
      end

      private

      def parse_result(output)
        return [] if output.blank?

        data = JSON.parse(output)
        data['faqs'] || []
      rescue JSON::ParserError
        []
      end
    end
  end
end

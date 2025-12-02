module Captain
  module Llm
    class ConversationFaqService
      DISTANCE_THRESHOLD = 0.3

      def initialize(assistant, conversation)
        @assistant = assistant
        @conversation = conversation
        @llm = Captain::LlmService.new(api_key: ENV.fetch('OPENAI_API_KEY', nil)) # Or from assistant config
      end

      def generate_and_deduplicate
        return [] unless human_interaction_exists?

        faqs = generate_faqs
        return [] if faqs.empty?

        process_faqs(faqs)
      end

      private

      def human_interaction_exists?
        @conversation.first_reply_created_at.present?
      end

      def process_faqs(faqs)
        unique_faqs = []

        faqs.each do |faq|
          if duplicate?(faq)
            log_duplicate(faq)
          else
            unique_faqs << faq
            save_faq(faq)
          end
        end

        unique_faqs
      end

      def duplicate?(faq)
        text = "#{faq['question']}: #{faq['answer']}"
        embedding = Captain::Llm::EmbeddingService.new.generate(text)

        similar = @assistant.responses.nearest_neighbors(:embedding, embedding, distance: 'cosine')
        similar.any? { |r| r.neighbor_distance < DISTANCE_THRESHOLD }
      end

      def save_faq(faq)
        @assistant.responses.create!(
          question: faq['question'],
          answer: faq['answer'],
          status: 'pending',
          documentable: @conversation
        )
      end

      def generate_faqs
        language = @conversation.account.locale_english_name
        messages = [
          { role: 'system', content: Captain::Llm::SystemPromptsService.conversation_faq_generator(language) },
          { role: 'user', content: conversation_content }
        ]

        response = @llm.call(messages, [], json_mode: true)
        parse_result(response[:output])
      rescue StandardError => e
        Rails.logger.error("ConversationFaqService Error: #{e.message}")
        []
      end

      def conversation_content
        @conversation.try(:to_llm_text) || @conversation.messages.pluck(:content).join("\n")
      end

      def parse_result(output)
        return [] if output.blank?

        data = JSON.parse(output)
        data['faqs'] || []
      rescue JSON::ParserError
        []
      end

      def log_duplicate(faq)
        Rails.logger.info("Duplicate FAQ found: #{faq['question']}")
      end
    end
  end
end

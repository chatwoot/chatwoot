module Captain
  module Tools
    class FaqLookupTool < BasePublicTool
      description 'Find relevant answers from the FAQ knowledge base using semantic search'
      param :query, type: 'string', desc: 'The search term or question to find answers for'

      def perform(_context, query:)
        log_tool_usage('search_initiated', { search_term: query })

        results = search_knowledge_base(query)

        if results.any?
          log_tool_usage('results_found', { count: results.size })
          compile_responses(results)
        else
          log_tool_usage('no_results_found', { search_term: query })
          "No matching FAQs found for: #{query}"
        end
      end

      private

      def search_knowledge_base(term)
        @assistant.responses.approved.search(term).to_a
      end

      def compile_responses(items)
        items.map { |item| build_response_text(item) }.join("\n")
      end

      def build_response_text(item)
        text = <<~RESPONSE
          Question: #{item.question}
          Answer: #{item.answer}
        RESPONSE

        text += "Source: #{item.documentable.external_link}\n" if include_source?(item)

        text
      end

      def include_source?(item)
        doc = item.documentable
        return false unless doc&.external_link.present?

        !doc.external_link.start_with?('PDF:')
      end
    end
  end
end

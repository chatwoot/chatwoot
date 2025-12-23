# frozen_string_literal: true

module PgSearch
  module Features
    class Trigram < Feature
      def self.valid_options
        super + %i[threshold word_similarity]
      end

      def conditions
        if options[:threshold]
          Arel::Nodes::Grouping.new(
            similarity.gteq(options[:threshold])
          )
        else
          Arel::Nodes::Grouping.new(
            Arel::Nodes::InfixOperation.new(
              infix_operator,
              normalized_query,
              normalized_document
            )
          )
        end
      end

      def rank
        Arel::Nodes::Grouping.new(similarity)
      end

      private

      def word_similarity?
        options[:word_similarity]
      end

      def similarity_function
        if word_similarity?
          'word_similarity'
        else
          'similarity'
        end
      end

      def infix_operator
        if word_similarity?
          '<%'
        else
          '%'
        end
      end

      def similarity
        Arel::Nodes::NamedFunction.new(
          similarity_function,
          [
            normalized_query,
            normalized_document
          ]
        )
      end

      def normalized_document
        Arel::Nodes::Grouping.new(Arel.sql(normalize(document)))
      end

      def normalized_query
        sanitized_query = connection.quote(query)
        Arel.sql(normalize(sanitized_query))
      end
    end
  end
end

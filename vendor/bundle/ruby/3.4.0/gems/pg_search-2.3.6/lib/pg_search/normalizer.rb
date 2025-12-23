# frozen_string_literal: true

module PgSearch
  class Normalizer
    def initialize(config)
      @config = config
    end

    def add_normalization(sql_expression)
      return sql_expression unless config.ignore.include?(:accents)

      sql_node = case sql_expression
                 when Arel::Nodes::Node
                   sql_expression
                 else
                   Arel.sql(sql_expression)
                 end

      Arel::Nodes::NamedFunction.new(
        PgSearch.unaccent_function,
        [sql_node]
      ).to_sql
    end

    private

    attr_reader :config
  end
end

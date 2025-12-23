# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

module PgSearch
  class ScopeOptions
    attr_reader :config, :feature_options, :model

    def initialize(config)
      @config = config
      @model = config.model
      @feature_options = config.feature_options
    end

    def apply(scope)
      scope = include_table_aliasing_for_rank(scope)
      rank_table_alias = scope.pg_search_rank_table_alias(include_counter: true)

      scope
        .joins(rank_join(rank_table_alias))
        .order(Arel.sql("#{rank_table_alias}.rank DESC, #{order_within_rank}"))
        .extend(WithPgSearchRank)
        .extend(WithPgSearchHighlight[feature_for(:tsearch)])
    end

    module WithPgSearchHighlight
      def self.[](tsearch)
        Module.new do
          include WithPgSearchHighlight
          define_method(:tsearch) { tsearch }
        end
      end

      def tsearch
        raise TypeError, "You need to instantiate this module with []"
      end

      def with_pg_search_highlight
        scope = self
        scope = scope.select("#{table_name}.*") unless scope.select_values.any?
        scope.select("(#{highlight}) AS pg_search_highlight")
      end

      def highlight
        tsearch.highlight.to_sql
      end
    end

    module WithPgSearchRank
      def with_pg_search_rank
        scope = self
        scope = scope.select("#{table_name}.*") unless scope.select_values.any?
        scope.select("#{pg_search_rank_table_alias}.rank AS pg_search_rank")
      end
    end

    module PgSearchRankTableAliasing
      def pg_search_rank_table_alias(include_counter: false)
        components = [arel_table.name]
        if include_counter
          count = increment_counter
          components << count if count > 0
        end

        Configuration.alias(components)
      end

      private

      def increment_counter
        @counter ||= 0
      ensure
        @counter += 1
      end
    end

    private

    delegate :connection, :quoted_table_name, to: :model

    def subquery
      model
        .unscoped
        .select("#{primary_key} AS pg_search_id")
        .select("#{rank} AS rank")
        .joins(subquery_join)
        .where(conditions)
        .limit(nil)
        .offset(nil)
    end

    def conditions
      config.features
            .reject { |_feature_name, feature_options| feature_options && feature_options[:sort_only] }
            .map { |feature_name, _feature_options| feature_for(feature_name).conditions }
            .inject { |accumulator, expression| Arel::Nodes::Or.new(accumulator, expression) }
    end

    def order_within_rank
      config.order_within_rank || "#{primary_key} ASC"
    end

    def primary_key
      "#{quoted_table_name}.#{connection.quote_column_name(model.primary_key)}"
    end

    def subquery_join
      if config.associations.any?
        config.associations.map do |association|
          association.join(primary_key)
        end.join(' ')
      end
    end

    FEATURE_CLASSES = {
      dmetaphone: Features::DMetaphone,
      tsearch: Features::TSearch,
      trigram: Features::Trigram
    }.freeze

    def feature_for(feature_name)
      feature_name = feature_name.to_sym
      feature_class = FEATURE_CLASSES[feature_name]

      raise ArgumentError, "Unknown feature: #{feature_name}" unless feature_class

      normalizer = Normalizer.new(config)

      feature_class.new(
        config.query,
        feature_options[feature_name],
        config.columns,
        config.model,
        normalizer
      )
    end

    def rank
      (config.ranking_sql || ":tsearch").gsub(/:(\w*)/) do
        feature_for(Regexp.last_match(1)).rank.to_sql
      end
    end

    def rank_join(rank_table_alias)
      "INNER JOIN (#{subquery.to_sql}) AS #{rank_table_alias} ON #{primary_key} = #{rank_table_alias}.pg_search_id"
    end

    def include_table_aliasing_for_rank(scope)
      return scope if scope.included_modules.include?(PgSearchRankTableAliasing)

      scope.all.spawn.tap do |new_scope|
        new_scope.instance_eval { extend PgSearchRankTableAliasing }
      end
    end
  end
end

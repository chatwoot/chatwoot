# frozen_string_literal: true

module PgSearch
  module Model
    extend ActiveSupport::Concern

    module ClassMethods
      def pg_search_scope(name, options)
        options_proc = if options.respond_to?(:call)
                         options
                       elsif options.respond_to?(:merge)
                         ->(query) { { query: query }.merge(options) }
                       else
                         raise ArgumentError, 'pg_search_scope expects a Hash or Proc'
                       end

        define_singleton_method(name) do |*args|
          config = Configuration.new(options_proc.call(*args), self)
          scope_options = ScopeOptions.new(config)
          scope_options.apply(self)
        end
      end

      def multisearchable(options = {})
        include PgSearch::Multisearchable
        class_attribute :pg_search_multisearchable_options
        self.pg_search_multisearchable_options = options
      end
    end

    def method_missing(symbol, *args)
      case symbol
      when :pg_search_rank
        raise PgSearchRankNotSelected unless respond_to?(:pg_search_rank)

        read_attribute(:pg_search_rank).to_f
      when :pg_search_highlight
        raise PgSearchHighlightNotSelected unless respond_to?(:pg_search_highlight)

        read_attribute(:pg_search_highlight)
      else
        super
      end
    end

    def respond_to_missing?(symbol, *args)
      case symbol
      when :pg_search_rank
        attributes.key?(:pg_search_rank)
      when :pg_search_highlight
        attributes.key?(:pg_search_highlight)
      else
        super
      end
    end
  end
end

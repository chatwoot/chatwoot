# frozen_string_literal: true

require "active_record"
require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/string/strip"

require "pg_search/configuration"
require "pg_search/features"
require "pg_search/model"
require "pg_search/multisearch"
require "pg_search/multisearchable"
require "pg_search/normalizer"
require "pg_search/scope_options"
require "pg_search/version"

module PgSearch
  autoload :Document, "pg_search/document"

  def self.included(base)
    ActiveSupport::Deprecation.warn <<~MESSAGE
      Directly including `PgSearch` into an Active Record model is deprecated and will be removed in pg_search 3.0.

      Please replace `include PgSearch` with `include PgSearch::Model`.
    MESSAGE

    base.include PgSearch::Model
  end

  mattr_accessor :multisearch_options
  self.multisearch_options = {}

  mattr_accessor :unaccent_function
  self.unaccent_function = "unaccent"

  class << self
    def multisearch(*args)
      PgSearch::Document.search(*args)
    end

    def disable_multisearch
      Thread.current["PgSearch.enable_multisearch"] = false
      yield
    ensure
      Thread.current["PgSearch.enable_multisearch"] = true
    end

    def multisearch_enabled?
      if Thread.current.key?("PgSearch.enable_multisearch")
        Thread.current["PgSearch.enable_multisearch"]
      else
        true
      end
    end
  end

  class PgSearchRankNotSelected < StandardError
    def message
      "You must chain .with_pg_search_rank after the pg_search_scope " \
        "to access the pg_search_rank attribute on returned records"
    end
  end

  class PgSearchHighlightNotSelected < StandardError
    def message
      "You must chain .with_pg_search_highlight after the pg_search_scope " \
        "to access the pg_search_highlight attribute on returned records"
    end
  end
end

require "pg_search/railtie" if defined?(Rails::Railtie)

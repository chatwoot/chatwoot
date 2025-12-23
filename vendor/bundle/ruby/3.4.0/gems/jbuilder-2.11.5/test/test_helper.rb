require "bundler/setup"

require "rails"

require "jbuilder"

require "active_support/core_ext/array/access"
require "active_support/cache/memory_store"
require "active_support/json"
require "active_model"

require "active_support/testing/autorun"
require "mocha/minitest"

ActiveSupport.test_order = :random

class << Rails
  def cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

Jbuilder::CollectionRenderer.collection_cache = Rails.cache

class Post < Struct.new(:id, :body, :author_name)
  def cache_key
    "post-#{id}"
  end
end

class Racer < Struct.new(:id, :name)
  extend ActiveModel::Naming
  include ActiveModel::Conversion
end

ActionView::Template.register_template_handler :jbuilder, JbuilderHandler

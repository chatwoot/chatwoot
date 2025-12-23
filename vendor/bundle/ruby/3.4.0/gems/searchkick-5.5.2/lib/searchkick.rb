# dependencies
require "active_support"
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/module/attr_internal"
require "active_support/core_ext/module/delegation"
require "active_support/notifications"
require "hashie"

# stdlib
require "forwardable"

# modules
require_relative "searchkick/controller_runtime"
require_relative "searchkick/index"
require_relative "searchkick/index_cache"
require_relative "searchkick/index_options"
require_relative "searchkick/indexer"
require_relative "searchkick/hash_wrapper"
require_relative "searchkick/log_subscriber"
require_relative "searchkick/model"
require_relative "searchkick/multi_search"
require_relative "searchkick/query"
require_relative "searchkick/reindex_queue"
require_relative "searchkick/record_data"
require_relative "searchkick/record_indexer"
require_relative "searchkick/relation"
require_relative "searchkick/relation_indexer"
require_relative "searchkick/reranking"
require_relative "searchkick/results"
require_relative "searchkick/script"
require_relative "searchkick/version"
require_relative "searchkick/where"

# integrations
require_relative "searchkick/railtie" if defined?(Rails)

module Searchkick
  # requires faraday
  autoload :Middleware, "searchkick/middleware"

  # background jobs
  autoload :BulkReindexJob,  "searchkick/bulk_reindex_job"
  autoload :ProcessBatchJob, "searchkick/process_batch_job"
  autoload :ProcessQueueJob, "searchkick/process_queue_job"
  autoload :ReindexV2Job,    "searchkick/reindex_v2_job"

  # errors
  class Error < StandardError; end
  class MissingIndexError < Error; end
  class UnsupportedVersionError < Error
    def message
      "This version of Searchkick requires Elasticsearch 7+ or OpenSearch 1+"
    end
  end
  class InvalidQueryError < Error; end
  class DangerousOperation < Error; end
  class ImportError < Error; end

  class << self
    attr_accessor :search_method_name, :timeout, :models, :client_options, :redis, :index_prefix, :index_suffix, :queue_name, :model_options, :client_type
    attr_writer :client, :env, :search_timeout
    attr_reader :aws_credentials
  end
  self.search_method_name = :search
  self.timeout = 10
  self.models = []
  self.client_options = {}
  self.queue_name = :searchkick
  self.model_options = {}

  def self.client
    @client ||= begin
      client_type =
        if self.client_type
          self.client_type
        elsif defined?(OpenSearch::Client) && defined?(Elasticsearch::Client)
          raise Error, "Multiple clients found - set Searchkick.client_type = :elasticsearch or :opensearch"
        elsif defined?(OpenSearch::Client)
          :opensearch
        elsif defined?(Elasticsearch::Client)
          :elasticsearch
        else
          raise Error, "No client found - install the `elasticsearch` or `opensearch-ruby` gem"
        end

      # check after client to ensure faraday is installed
      # TODO remove in Searchkick 6
      if defined?(Typhoeus) && Gem::Version.new(Faraday::VERSION) < Gem::Version.new("0.14.0")
        require "typhoeus/adapters/faraday"
      end

      if client_type == :opensearch
        OpenSearch::Client.new({
          url: ENV["OPENSEARCH_URL"],
          # TODO remove headers in Searchkick 6
          transport_options: {request: {timeout: timeout}, headers: {content_type: "application/json"}},
          retry_on_failure: 2
        }.deep_merge(client_options)) do |f|
          f.use Searchkick::Middleware
          f.request :aws_sigv4, signer_middleware_aws_params if aws_credentials
        end
      else
        raise Error, "The `elasticsearch` gem must be 7+" if Elasticsearch::VERSION.to_i < 7

        transport_options = {request: {timeout: timeout}}
        # TODO remove headers in Searchkick 6
        if Elasticsearch::VERSION.to_i < 9
          transport_options[:headers] = {content_type: "application/json"}
        end

        Elasticsearch::Client.new({
          url: ENV["ELASTICSEARCH_URL"],
          transport_options: transport_options,
          retry_on_failure: 2
        }.deep_merge(client_options)) do |f|
          f.use Searchkick::Middleware
          f.request :aws_sigv4, signer_middleware_aws_params if aws_credentials
        end
      end
    end
  end

  def self.env
    @env ||= ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
  end

  def self.search_timeout
    (defined?(@search_timeout) && @search_timeout) || timeout
  end

  # private
  def self.server_info
    @server_info ||= client.info
  end

  def self.server_version
    @server_version ||= server_info["version"]["number"]
  end

  def self.opensearch?
    unless defined?(@opensearch)
      @opensearch = server_info["version"]["distribution"] == "opensearch"
    end
    @opensearch
  end

  # TODO always check true version in Searchkick 6
  def self.server_below?(version, true_version = false)
    server_version = !true_version && opensearch? ? "7.10.2" : self.server_version
    Gem::Version.new(server_version.split("-")[0]) < Gem::Version.new(version.split("-")[0])
  end

  # private
  def self.knn_support?
    if opensearch?
      !server_below?("2.4.0", true)
    else
      !server_below?("8.6.0")
    end
  end

  def self.search(term = "*", model: nil, **options, &block)
    options = options.dup
    klass = model

    # convert index_name into models if possible
    # this should allow for easier upgrade
    if options[:index_name] && !options[:models] && Array(options[:index_name]).all? { |v| v.respond_to?(:searchkick_index) }
      options[:models] = options.delete(:index_name)
    end

    # make Searchkick.search(models: [Product]) and Product.search equivalent
    unless klass
      models = Array(options[:models])
      if models.size == 1
        klass = models.first
        options.delete(:models)
      end
    end

    if klass
      if (options[:models] && Array(options[:models]) != [klass]) || Array(options[:index_name]).any? { |v| v.respond_to?(:searchkick_index) && v != klass }
        raise ArgumentError, "Use Searchkick.search to search multiple models"
      end
    end

    # TODO remove in Searchkick 6
    if options[:execute] == false
      Searchkick.warn("The execute option is no longer needed")
      options.delete(:execute)
    end

    options = options.merge(block: block) if block
    Relation.new(klass, term, **options)
  end

  def self.multi_search(queries)
    return if queries.empty?

    queries = queries.map { |q| q.send(:query) }
    event = {
      name: "Multi Search",
      body: queries.flat_map { |q| [q.params.except(:body).to_json, q.body.to_json] }.map { |v| "#{v}\n" }.join
    }
    ActiveSupport::Notifications.instrument("multi_search.searchkick", event) do
      MultiSearch.new(queries).perform
    end
  end

  # script

  # experimental
  def self.script(source, **options)
    Script.new(source, **options)
  end

  # callbacks

  def self.enable_callbacks
    self.callbacks_value = nil
  end

  def self.disable_callbacks
    self.callbacks_value = false
  end

  def self.callbacks?(default: true)
    if callbacks_value.nil?
      default
    else
      callbacks_value != false
    end
  end

  # message is private
  def self.callbacks(value = nil, message: nil)
    if block_given?
      previous_value = callbacks_value
      begin
        self.callbacks_value = value
        result = yield
        if callbacks_value == :bulk && indexer.queued_items.any?
          event = {}
          if message
            message.call(event)
          else
            event[:name] = "Bulk"
            event[:count] = indexer.queued_items.size
          end
          ActiveSupport::Notifications.instrument("request.searchkick", event) do
            indexer.perform
          end
        end
        result
      ensure
        self.callbacks_value = previous_value
      end
    else
      self.callbacks_value = value
    end
  end

  def self.aws_credentials=(creds)
    require "faraday_middleware/aws_sigv4"

    @aws_credentials = creds
    @client = nil # reset client
  end

  def self.reindex_status(index_name)
    raise Error, "Redis not configured" unless redis

    batches_left = Index.new(index_name).batches_left
    {
      completed: batches_left == 0,
      batches_left: batches_left
    }
  end

  def self.with_redis
    if redis
      if redis.respond_to?(:with)
        redis.with do |r|
          yield r
        end
      else
        yield redis
      end
    end
  end

  def self.warn(message)
    super("[searchkick] WARNING: #{message}")
  end

  # private
  def self.load_records(relation, ids)
    relation =
      if relation.respond_to?(:primary_key)
        primary_key = relation.primary_key
        raise Error, "Need primary key to load records" if !primary_key

        relation.where(primary_key => ids)
      elsif relation.respond_to?(:queryable)
        relation.queryable.for_ids(ids)
      end

    raise Error, "Not sure how to load records" if !relation

    relation
  end

  # public (for reindexing conversions)
  def self.load_model(class_name, allow_child: false)
    model = class_name.safe_constantize
    raise Error, "Could not find class: #{class_name}" unless model
    if allow_child
      unless model.respond_to?(:searchkick_klass)
        raise Error, "#{class_name} is not a searchkick model"
      end
    else
      unless Searchkick.models.include?(model)
        raise Error, "#{class_name} is not a searchkick model"
      end
    end
    model
  end

  # private
  def self.indexer
    Thread.current[:searchkick_indexer] ||= Indexer.new
  end

  # private
  def self.callbacks_value
    Thread.current[:searchkick_callbacks_enabled]
  end

  # private
  def self.callbacks_value=(value)
    Thread.current[:searchkick_callbacks_enabled] = value
  end

  # private
  def self.signer_middleware_aws_params
    {service: "es", region: "us-east-1"}.merge(aws_credentials)
  end

  # private
  # methods are forwarded to base class
  # this check to see if scope exists on that class
  # it's a bit tricky, but this seems to work
  def self.relation?(klass)
    if klass.respond_to?(:current_scope)
      !klass.current_scope.nil?
    else
      klass.is_a?(Mongoid::Criteria) || !Mongoid::Threaded.current_scope(klass).nil?
    end
  end

  # private
  def self.scope(model)
    # safety check to make sure used properly in code
    raise Error, "Cannot scope relation" if relation?(model)

    if model.searchkick_options[:unscope]
      model.unscoped
    else
      model
    end
  end

  # private
  def self.not_found_error?(e)
    (defined?(Elastic::Transport) && e.is_a?(Elastic::Transport::Transport::Errors::NotFound)) ||
    (defined?(Elasticsearch::Transport) && e.is_a?(Elasticsearch::Transport::Transport::Errors::NotFound)) ||
    (defined?(OpenSearch) && e.is_a?(OpenSearch::Transport::Transport::Errors::NotFound))
  end

  # private
  def self.transport_error?(e)
    (defined?(Elastic::Transport) && e.is_a?(Elastic::Transport::Transport::Error)) ||
    (defined?(Elasticsearch::Transport) && e.is_a?(Elasticsearch::Transport::Transport::Error)) ||
    (defined?(OpenSearch) && e.is_a?(OpenSearch::Transport::Transport::Error))
  end

  # private
  def self.not_allowed_error?(e)
    (defined?(Elastic::Transport) && e.is_a?(Elastic::Transport::Transport::Errors::MethodNotAllowed)) ||
    (defined?(Elasticsearch::Transport) && e.is_a?(Elasticsearch::Transport::Transport::Errors::MethodNotAllowed)) ||
    (defined?(OpenSearch) && e.is_a?(OpenSearch::Transport::Transport::Errors::MethodNotAllowed))
  end
end

ActiveSupport.on_load(:active_record) do
  extend Searchkick::Model
end

ActiveSupport.on_load(:mongoid) do
  Mongoid::Document::ClassMethods.include Searchkick::Model
end

ActiveSupport.on_load(:action_controller) do
  include Searchkick::ControllerRuntime
end

Searchkick::LogSubscriber.attach_to :searchkick

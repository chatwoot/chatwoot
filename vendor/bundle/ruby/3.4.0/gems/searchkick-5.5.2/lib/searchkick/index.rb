module Searchkick
  class Index
    attr_reader :name, :options

    def initialize(name, options = {})
      @name = name
      @options = options
      @klass_document_type = {} # cache
    end

    def index_options
      IndexOptions.new(self).index_options
    end

    def create(body = {})
      client.indices.create index: name, body: body
    end

    def delete
      if alias_exists?
        # can't call delete directly on aliases in ES 6
        indices = client.indices.get_alias(name: name).keys
        client.indices.delete index: indices
      else
        client.indices.delete index: name
      end
    end

    def exists?
      client.indices.exists index: name
    end

    def refresh
      client.indices.refresh index: name
    end

    def alias_exists?
      client.indices.exists_alias name: name
    end

    # call to_h for consistent results between elasticsearch gem 7 and 8
    # could do for all API calls, but just do for ones where return value is focus for now
    def mapping
      client.indices.get_mapping(index: name).to_h
    end

    # call to_h for consistent results between elasticsearch gem 7 and 8
    def settings
      client.indices.get_settings(index: name).to_h
    end

    def refresh_interval
      index_settings["refresh_interval"]
    end

    def update_settings(settings)
      client.indices.put_settings index: name, body: settings
    end

    def tokens(text, options = {})
      client.indices.analyze(body: {text: text}.merge(options), index: name)["tokens"].map { |t| t["token"] }
    end

    def total_docs
      response =
        client.search(
          index: name,
          body: {
            query: {match_all: {}},
            size: 0,
            track_total_hits: true
          }
        )

      Results.new(nil, response).total_count
    end

    def promote(new_name, update_refresh_interval: false)
      if update_refresh_interval
        new_index = Index.new(new_name, @options)
        settings = options[:settings] || {}
        refresh_interval = (settings[:index] && settings[:index][:refresh_interval]) || "1s"
        new_index.update_settings(index: {refresh_interval: refresh_interval})
      end

      old_indices =
        begin
          client.indices.get_alias(name: name).keys
        rescue => e
          raise e unless Searchkick.not_found_error?(e)
          {}
        end
      actions = old_indices.map { |old_name| {remove: {index: old_name, alias: name}} } + [{add: {index: new_name, alias: name}}]
      client.indices.update_aliases body: {actions: actions}
    end
    alias_method :swap, :promote

    def retrieve(record)
      record_data = RecordData.new(self, record).record_data

      # remove underscore
      get_options = record_data.to_h { |k, v| [k.to_s.delete_prefix("_").to_sym, v] }

      client.get(get_options)["_source"]
    end

    def all_indices(unaliased: false)
      indices =
        begin
          if client.indices.respond_to?(:get_alias)
            client.indices.get_alias(index: "#{name}*")
          else
            client.indices.get_aliases
          end
        rescue => e
          raise e unless Searchkick.not_found_error?(e)
          {}
        end
      indices = indices.select { |_k, v| v.empty? || v["aliases"].empty? } if unaliased
      indices.select { |k, _v| k =~ /\A#{Regexp.escape(name)}_\d{14,17}\z/ }.keys
    end

    # remove old indices that start w/ index_name
    def clean_indices
      indices = all_indices(unaliased: true)
      indices.each do |index|
        Index.new(index).delete
      end
      indices
    end

    def store(record)
      notify(record, "Store") do
        queue_index([record])
      end
    end

    def remove(record)
      notify(record, "Remove") do
        queue_delete([record])
      end
    end

    def update_record(record, method_name)
      notify(record, "Update") do
        queue_update([record], method_name)
      end
    end

    def bulk_delete(records)
      return if records.empty?

      notify_bulk(records, "Delete") do
        queue_delete(records)
      end
    end

    def bulk_index(records)
      return if records.empty?

      notify_bulk(records, "Import") do
        queue_index(records)
      end
    end
    alias_method :import, :bulk_index

    def bulk_update(records, method_name)
      return if records.empty?

      notify_bulk(records, "Update") do
        queue_update(records, method_name)
      end
    end

    def search_id(record)
      RecordData.new(self, record).search_id
    end

    def document_type(record)
      RecordData.new(self, record).document_type
    end

    def similar_record(record, **options)
      options[:per_page] ||= 10
      options[:similar] = [RecordData.new(self, record).record_data]
      options[:models] ||= [record.class] unless options.key?(:model)

      Searchkick.search("*", **options)
    end

    def reload_synonyms
      if Searchkick.opensearch?
        client.transport.perform_request "POST", "_plugins/_refresh_search_analyzers/#{CGI.escape(name)}"
      else
        raise Error, "Requires Elasticsearch 7.3+" if Searchkick.server_below?("7.3.0")
        begin
          client.transport.perform_request("GET", "#{CGI.escape(name)}/_reload_search_analyzers")
        rescue => e
          raise Error, "Requires non-OSS version of Elasticsearch" if Searchkick.not_allowed_error?(e)
          raise e
        end
      end
    end

    # queue

    def reindex_queue
      ReindexQueue.new(name)
    end

    # reindex

    # note: this is designed to be used internally
    # so it does not check object matches index class
    def reindex(object, method_name: nil, full: false, **options)
      if object.is_a?(Array)
        # note: purposefully skip full
        return reindex_records(object, method_name: method_name, **options)
      end

      if !object.respond_to?(:searchkick_klass)
        raise Error, "Cannot reindex object"
      end

      scoped = Searchkick.relation?(object)
      # call searchkick_klass for inheritance
      relation = scoped ? object.all : Searchkick.scope(object.searchkick_klass).all

      refresh = options.fetch(:refresh, !scoped)
      options.delete(:refresh)

      if method_name || (scoped && !full)
        mode = options.delete(:mode) || :inline
        scope = options.delete(:scope)
        raise ArgumentError, "unsupported keywords: #{options.keys.map(&:inspect).join(", ")}" if options.any?

        # import only
        import_scope(relation, method_name: method_name, mode: mode, scope: scope)
        self.refresh if refresh
        true
      else
        async = options.delete(:async)
        if async
          if async.is_a?(Hash) && async[:wait]
            # TODO warn in 5.1
            # Searchkick.warn "async option is deprecated - use mode: :async, wait: true instead"
            options[:wait] = true unless options.key?(:wait)
          else
            # TODO warn in 5.1
            # Searchkick.warn "async option is deprecated - use mode: :async instead"
          end
          options[:mode] ||= :async
        end

        full_reindex(relation, **options)
      end
    end

    def create_index(index_options: nil)
      index_options ||= self.index_options
      index = Index.new("#{name}_#{Time.now.strftime('%Y%m%d%H%M%S%L')}", @options)
      index.create(index_options)
      index
    end

    def import_scope(relation, **options)
      relation_indexer.reindex(relation, **options)
    end

    def batches_left
      relation_indexer.batches_left
    end

    # private
    def klass_document_type(klass, ignore_type = false)
      @klass_document_type[[klass, ignore_type]] ||= begin
        if !ignore_type && klass.searchkick_klass.searchkick_options[:_type]
          type = klass.searchkick_klass.searchkick_options[:_type]
          type = type.call if type.respond_to?(:call)
          type
        else
          klass.model_name.to_s.underscore
        end
      end
    end

    # private
    def conversions_fields
      @conversions_fields ||= begin
        conversions = Array(options[:conversions])
        conversions.map(&:to_s) + conversions.map(&:to_sym)
      end
    end

    # private
    def suggest_fields
      @suggest_fields ||= Array(options[:suggest]).map(&:to_s)
    end

    # private
    def locations_fields
      @locations_fields ||= begin
        locations = Array(options[:locations])
        locations.map(&:to_s) + locations.map(&:to_sym)
      end
    end

    # private
    def uuid
      index_settings["uuid"]
    end

    protected

    def client
      Searchkick.client
    end

    def queue_index(records)
      Searchkick.indexer.queue(records.map { |r| RecordData.new(self, r).index_data })
    end

    def queue_delete(records)
      Searchkick.indexer.queue(records.reject { |r| r.id.blank? }.map { |r| RecordData.new(self, r).delete_data })
    end

    def queue_update(records, method_name)
      Searchkick.indexer.queue(records.map { |r| RecordData.new(self, r).update_data(method_name) })
    end

    def relation_indexer
      @relation_indexer ||= RelationIndexer.new(self)
    end

    def index_settings
      settings.values.first["settings"]["index"]
    end

    def import_before_promotion(index, relation, **import_options)
      index.import_scope(relation, **import_options)
    end

    def reindex_records(object, mode: nil, refresh: false, **options)
      mode ||= Searchkick.callbacks_value || @options[:callbacks] || :inline
      mode = :inline if mode == :bulk

      result = RecordIndexer.new(self).reindex(object, mode: mode, full: false, **options)
      self.refresh if refresh
      result
    end

    # https://gist.github.com/jarosan/3124884
    # http://www.elasticsearch.org/blog/changing-mapping-with-zero-downtime/
    def full_reindex(relation, import: true, resume: false, retain: false, mode: nil, refresh_interval: nil, scope: nil, wait: nil)
      raise ArgumentError, "wait only available in :async mode" if !wait.nil? && mode != :async
      # TODO raise ArgumentError in Searchkick 6
      Searchkick.warn("Full reindex does not support :queue mode - use :async mode instead") if mode == :queue

      if resume
        index_name = all_indices.sort.last
        raise Error, "No index to resume" unless index_name
        index = Index.new(index_name, @options)
      else
        clean_indices unless retain

        index_options = relation.searchkick_index_options
        index_options.deep_merge!(settings: {index: {refresh_interval: refresh_interval}}) if refresh_interval
        index = create_index(index_options: index_options)
      end

      import_options = {
        mode: (mode || :inline),
        full: true,
        resume: resume,
        scope: scope
      }

      uuid = index.uuid

      # check if alias exists
      alias_exists = alias_exists?
      if alias_exists
        import_before_promotion(index, relation, **import_options) if import

        # get existing indices to remove
        unless mode == :async
          check_uuid(uuid, index.uuid)
          promote(index.name, update_refresh_interval: !refresh_interval.nil?)
          clean_indices unless retain
        end
      else
        delete if exists?
        promote(index.name, update_refresh_interval: !refresh_interval.nil?)

        # import after promotion
        index.import_scope(relation, **import_options) if import
      end

      if mode == :async
        if wait
          puts "Created index: #{index.name}"
          puts "Jobs queued. Waiting..."
          loop do
            sleep 3
            status = Searchkick.reindex_status(index.name)
            break if status[:completed]
            puts "Batches left: #{status[:batches_left]}"
          end
          # already promoted if alias didn't exist
          if alias_exists
            puts "Jobs complete. Promoting..."
            check_uuid(uuid, index.uuid)
            promote(index.name, update_refresh_interval: !refresh_interval.nil?)
          end
          clean_indices unless retain
          puts "SUCCESS!"
        end

        {index_name: index.name}
      else
        index.refresh
        true
      end
    rescue => e
      if Searchkick.transport_error?(e) && (e.message.include?("No handler for type [text]") || e.message.include?("class java.util.ArrayList cannot be cast to class java.util.Map"))
        raise UnsupportedVersionError
      end

      raise e
    end

    # safety check
    # still a chance for race condition since its called before promotion
    # ideal is for user to disable automatic index creation
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-index_.html#index-creation
    def check_uuid(old_uuid, new_uuid)
      if old_uuid != new_uuid
        raise Error, "Safety check failed - only run one Model.reindex per model at a time"
      end
    end

    def notify(record, name)
      if Searchkick.callbacks_value == :bulk
        yield
      else
        name = "#{record.class.searchkick_klass.name} #{name}" if record && record.class.searchkick_klass
        event = {
          name: name,
          id: search_id(record)
        }
        ActiveSupport::Notifications.instrument("request.searchkick", event) do
          yield
        end
      end
    end

    def notify_bulk(records, name)
      if Searchkick.callbacks_value == :bulk
        yield
      else
        event = {
          name: "#{records.first.class.searchkick_klass.name} #{name}",
          count: records.size
        }
        ActiveSupport::Notifications.instrument("request.searchkick", event) do
          yield
        end
      end
    end
  end
end

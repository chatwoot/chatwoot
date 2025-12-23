module Searchkick
  class RecordIndexer
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def reindex(records, mode:, method_name:, full: false, single: false)
      # prevents exists? check if records is a relation
      records = records.to_a
      return if records.empty?

      case mode
      when :async
        unless defined?(ActiveJob)
          raise Error, "Active Job not found"
        end

        # we could likely combine ReindexV2Job, BulkReindexJob, and ProcessBatchJob
        # but keep them separate for now
        if single
          record = records.first

          # always pass routing in case record is deleted
          # before the async job runs
          if record.respond_to?(:search_routing)
            routing = record.search_routing
          end

          Searchkick::ReindexV2Job.perform_later(
            record.class.name,
            record.id.to_s,
            method_name ? method_name.to_s : nil,
            routing: routing,
            index_name: index.name
          )
        else
          Searchkick::BulkReindexJob.perform_later(
            class_name: records.first.class.searchkick_options[:class_name],
            record_ids: records.map { |r| r.id.to_s },
            index_name: index.name,
            method_name: method_name ? method_name.to_s : nil
          )
        end
      when :queue
        if method_name
          raise Error, "Partial reindex not supported with queue option"
        end

        index.reindex_queue.push_records(records)
      when true, :inline
        index_records, other_records = records.partition { |r| index_record?(r) }
        import_inline(index_records, !full ? other_records : [], method_name: method_name, single: single)
      else
        raise ArgumentError, "Invalid value for mode"
      end

      # return true like model and relation reindex for now
      true
    end

    def reindex_items(klass, items, method_name:, single: false)
      routing = items.to_h { |r| [r[:id], r[:routing]] }
      record_ids = routing.keys

      relation = Searchkick.load_records(klass, record_ids)
      # call search_import even for single records for nested associations
      relation = relation.search_import if relation.respond_to?(:search_import)
      records = relation.select(&:should_index?)

      # determine which records to delete
      delete_ids = record_ids - records.map { |r| r.id.to_s }
      delete_records =
        delete_ids.map do |id|
          construct_record(klass, id, routing[id])
        end

      import_inline(records, delete_records, method_name: method_name, single: single)
    end

    private

    def index_record?(record)
      record.persisted? && !record.destroyed? && record.should_index?
    end

    # import in single request with retries
    def import_inline(index_records, delete_records, method_name:, single:)
      return if index_records.empty? && delete_records.empty?

      maybe_bulk(index_records, delete_records, method_name, single) do
        if index_records.any?
          if method_name
            index.bulk_update(index_records, method_name)
          else
            index.bulk_index(index_records)
          end
        end

        if delete_records.any?
          index.bulk_delete(delete_records)
        end
      end
    end

    def maybe_bulk(index_records, delete_records, method_name, single)
      if Searchkick.callbacks_value == :bulk
        yield
      else
        # set action and data
        action =
          if single && index_records.empty?
            "Remove"
          elsif method_name
            "Update"
          else
            single ? "Store" : "Import"
          end
        record = index_records.first || delete_records.first
        name = record.class.searchkick_klass.name
        message = lambda do |event|
          event[:name] = "#{name} #{action}"
          if single
            event[:id] = index.search_id(record)
          else
            event[:count] = index_records.size + delete_records.size
          end
        end

        with_retries do
          Searchkick.callbacks(:bulk, message: message) do
            yield
          end
        end
      end
    end

    def construct_record(klass, id, routing)
      record = klass.new
      record.id = id
      if routing
        record.define_singleton_method(:search_routing) do
          routing
        end
      end
      record
    end

    def with_retries
      retries = 0

      begin
        yield
      rescue Faraday::ClientError => e
        if retries < 1
          retries += 1
          retry
        end
        raise e
      end
    end
  end
end

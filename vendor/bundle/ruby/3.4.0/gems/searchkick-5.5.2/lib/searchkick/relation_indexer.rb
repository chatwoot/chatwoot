module Searchkick
  class RelationIndexer
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def reindex(relation, mode:, method_name: nil, full: false, resume: false, scope: nil)
      # apply scopes
      if scope
        relation = relation.send(scope)
      elsif relation.respond_to?(:search_import)
        relation = relation.search_import
      end

      # remove unneeded loading for async and queue
      if mode == :async || mode == :queue
        if relation.respond_to?(:primary_key)
          relation = relation.except(:includes, :preload)
          unless mode == :queue && relation.klass.method_defined?(:search_routing)
            relation = relation.except(:select).select(relation.primary_key)
          end
        elsif relation.respond_to?(:only)
          unless mode == :queue && relation.klass.method_defined?(:search_routing)
            relation = relation.only(:_id)
          end
        end
      end

      if mode == :async && full
        return full_reindex_async(relation)
      end

      relation = resume_relation(relation) if resume

      reindex_options = {
        mode: mode,
        method_name: method_name,
        full: full
      }
      record_indexer = RecordIndexer.new(index)

      in_batches(relation) do |items|
        record_indexer.reindex(items, **reindex_options)
      end
    end

    def batches_left
      Searchkick.with_redis { |r| r.call("SCARD", batches_key) }
    end

    def batch_completed(batch_id)
      Searchkick.with_redis { |r| r.call("SREM", batches_key, [batch_id]) }
    end

    private

    def resume_relation(relation)
      if relation.respond_to?(:primary_key)
        # use total docs instead of max id since there's not a great way
        # to get the max _id without scripting since it's a string
        where = relation.arel_table[relation.primary_key].gt(index.total_docs)
        relation = relation.where(where)
      else
        raise Error, "Resume not supported for Mongoid"
      end
    end

    def in_batches(relation)
      if relation.respond_to?(:find_in_batches)
        klass = relation.klass
        # remove order to prevent possible warnings
        relation.except(:order).find_in_batches(batch_size: batch_size) do |batch|
          # prevent scope from affecting search_data as well as inline jobs
          # Active Record runs relation calls in scoping block
          # https://github.com/rails/rails/blob/main/activerecord/lib/active_record/relation/delegation.rb
          # note: we could probably just call klass.current_scope = nil
          # anywhere in reindex method (after initial all call),
          # but this is more cautious
          previous_scope = klass.current_scope(true)
          if previous_scope
            begin
              klass.current_scope = nil
              yield batch
            ensure
              klass.current_scope = previous_scope
            end
          else
            yield batch
          end
        end
      else
        klass = relation.klass
        each_batch(relation, batch_size: batch_size) do |batch|
          # prevent scope from affecting search_data as well as inline jobs
          # note: Model.with_scope doesn't always restore scope, so use custom logic
          previous_scope = Mongoid::Threaded.current_scope(klass)
          if previous_scope
            begin
              Mongoid::Threaded.set_current_scope(nil, klass)
              yield batch
            ensure
              Mongoid::Threaded.set_current_scope(previous_scope, klass)
            end
          else
            yield batch
          end
        end
      end
    end

    def each_batch(relation, batch_size:)
      # https://github.com/karmi/tire/blob/master/lib/tire/model/import.rb
      # use cursor for Mongoid
      items = []
      relation.all.each do |item|
        items << item
        if items.length == batch_size
          yield items
          items = []
        end
      end
      yield items if items.any?
    end

    def batch_size
      @batch_size ||= index.options[:batch_size] || 1000
    end

    def full_reindex_async(relation)
      batch_id = 1
      class_name = relation.searchkick_options[:class_name]

      in_batches(relation) do |items|
        batch_job(class_name, batch_id, items.map(&:id))
        batch_id += 1
      end
    end

    def batch_job(class_name, batch_id, record_ids)
      Searchkick.with_redis { |r| r.call("SADD", batches_key, [batch_id]) }
      Searchkick::BulkReindexJob.perform_later(
        class_name: class_name,
        index_name: index.name,
        batch_id: batch_id,
        record_ids: record_ids.map { |v| v.instance_of?(Integer) ? v : v.to_s }
      )
    end

    def batches_key
      "searchkick:reindex:#{index.name}:batches"
    end
  end
end

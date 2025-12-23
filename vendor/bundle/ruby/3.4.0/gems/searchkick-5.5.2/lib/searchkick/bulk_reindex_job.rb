module Searchkick
  class BulkReindexJob < ActiveJob::Base
    queue_as { Searchkick.queue_name }

    # TODO remove min_id and max_id in Searchkick 6
    def perform(class_name:, record_ids: nil, index_name: nil, method_name: nil, batch_id: nil, min_id: nil, max_id: nil)
      model = Searchkick.load_model(class_name)
      index = model.searchkick_index(name: index_name)

      # legacy
      record_ids ||= min_id..max_id

      relation = Searchkick.scope(model)
      relation = Searchkick.load_records(relation, record_ids)
      relation = relation.search_import if relation.respond_to?(:search_import)

      RecordIndexer.new(index).reindex(relation, mode: :inline, method_name: method_name, full: false)
      RelationIndexer.new(index).batch_completed(batch_id) if batch_id
    end
  end
end

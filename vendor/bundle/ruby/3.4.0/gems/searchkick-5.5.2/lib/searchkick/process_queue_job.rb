module Searchkick
  class ProcessQueueJob < ActiveJob::Base
    queue_as { Searchkick.queue_name }

    def perform(class_name:, index_name: nil, inline: false)
      model = Searchkick.load_model(class_name)
      index = model.searchkick_index(name: index_name)
      limit = model.searchkick_options[:batch_size] || 1000

      loop do
        record_ids = index.reindex_queue.reserve(limit: limit)
        if record_ids.any?
          batch_options = {
            class_name: class_name,
            record_ids: record_ids.uniq,
            index_name: index_name
          }

          if inline
            # use new.perform to avoid excessive logging
            Searchkick::ProcessBatchJob.new.perform(**batch_options)
          else
            Searchkick::ProcessBatchJob.perform_later(**batch_options)
          end

          # TODO when moving to reliable queuing, mark as complete
        end
        break unless record_ids.size == limit
      end
    end
  end
end

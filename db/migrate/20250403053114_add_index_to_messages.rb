class AddIndexToMessages < ActiveRecord::Migration[7.0]
  def up
    # Enqueue the index creation job to be processed by Sidekiq
    DatabaseIndexWorker.perform_async('create')
  end

  def down
    # Enqueue the index dropping job to be processed by Sidekiq
    DatabaseIndexWorker.perform_async('drop')
  end
end

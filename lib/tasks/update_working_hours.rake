namespace :conversations do
  desc 'Update working_hours key for conversations created in last 30 days'
  task update_working_hours: :environment do
    include WorkingHoursHelper
    require 'parallel'

    start_time = Time.current
    puts "Starting working hours update at #{start_time}"

    conversations = Conversation.where('created_at > ?', 1.day.ago)
    total = conversations.count

    # Create atomic counters for thread-safe counting
    updated = Concurrent::AtomicFixnum.new(0)
    errors = Concurrent::AtomicFixnum.new(0)

    puts "Processing #{total} conversations..."

    # Process in batches, then parallelize within each batch
    conversations.in_batches(of: 1000) do |batch|
      Parallel.each(batch, in_threads: 3) do |conversation|
        begin
          # Ensure we release connections back to the pool after each operation
          ActiveRecord::Base.connection_pool.with_connection do
            Current.account = conversation.account

            conversation.additional_attributes ||= {}
            conversation.additional_attributes['working_hours'] = in_working_hours(conversation.created_at)

            if conversation.save
              updated.increment
            else
              errors.increment
              puts "Error updating conversation #{conversation.id}: #{conversation.errors.full_messages.join(', ')}"
            end
          end
        rescue => e
          errors.increment
          puts "Error processing conversation #{conversation.id}: #{e.message}"
        end
      end

      # After each batch, output progress
      progress = ((updated.value + errors.value).to_f / total * 100).round(2)
      puts "\nBatch completed. Overall progress: #{progress}%"
      puts "Current stats - Updated: #{updated.value}, Errors: #{errors.value}"
    end

    end_time = Time.current
    duration = (end_time - start_time).round(2)

    puts "\nTask completed in #{duration} seconds"
    puts "Total conversations processed: #{total}"
    puts "Successfully updated: #{updated.value}"
    puts "Errors: #{errors.value}"
  end
end

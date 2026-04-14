# Monitor bulk reindex progress
# RAILS_ENV=production bundle exec rails runner script/monitor_reindex.rb

puts 'Monitoring bulk reindex progress (Ctrl+C to stop)...'
puts ''

loop do
  bulk_queue = Sidekiq::Queue.new('bulk_reindex_low')
  prod_queue = Sidekiq::Queue.new('async_database_migration')
  retry_set = Sidekiq::RetrySet.new

  puts "[#{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')}]"
  puts "  Bulk Reindex Queue: #{bulk_queue.size} jobs"
  puts "  Production Queue: #{prod_queue.size} jobs"
  puts "  Retry Queue: #{retry_set.size} jobs"
  puts "  #{('-' * 60)}"

  sleep(30)
end

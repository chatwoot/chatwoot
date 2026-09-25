# Monitor bulk reindex progress
# RAILS_ENV=production bundle exec rails runner script/monitor_reindex.rb

puts 'Monitoring bulk reindex progress (Ctrl+C to stop)...'
puts ''

loop do
  queue = Sidekiq::Queue.new('within_1_day')
  retry_set = Sidekiq::RetrySet.new

  puts "[#{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')}]"
  puts "  within_1_day queue: #{queue.size} jobs"
  puts "  Retry Queue: #{retry_set.size} jobs"
  puts "  #{('-' * 60)}"

  sleep(30)
end

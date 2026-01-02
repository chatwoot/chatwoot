# Reindex messages for a single account
# Usage: bundle exec rails runner script/reindex_single_account.rb ACCOUNT_ID [DAYS_BACK]

#account_id = ARGV[0]&.to_i
days_back = (ARGV[1] || 30).to_i

# if account_id.nil? || account_id.zero?
#   puts "Usage: bundle exec rails runner script/reindex_single_account.rb ACCOUNT_ID [DAYS_BACK]"
#   puts "Example: bundle exec rails runner script/reindex_single_account.rb 93293 30"
#   exit 1
# end

# account = Account.find(account_id)
# puts "=" * 80
# puts "Reindexing messages for: #{account.name} (ID: #{account.id})"
# puts "=" * 80

# Enable feature if not already enabled
# unless account.feature_enabled?('advanced_search_indexing')
#   puts "Enabling advanced_search_indexing feature..."
#   account.enable_features(:advanced_search_indexing)
#   account.save!
# end

# Get messages to index
# messages = Message.where(account_id: account.id)
#                   .where(message_type: [0, 1])  # incoming/outgoing only
#                   .where('created_at >= ?', days_back.days.ago)

messages = Message.where('created_at >= ?', days_back.days.ago)

puts "Found #{messages.count} messages to index (last #{days_back} days)"
puts ''

sleep(15)

# Create bulk reindex jobs
index_name = Message.searchkick_index.name
batch_count = 0

messages.find_in_batches(batch_size: 1000).with_index do |batch, index|
  Searchkick::BulkReindexJob.set(queue: :bulk_reindex_low).perform_later(
    class_name: 'Message',
    index_name: index_name,
    batch_id: index,
    record_ids: batch.map(&:id)
  )

  batch_count += 1
  print '.'
  sleep(0.5)  # Small delay
end

puts ''
puts '=' * 80
puts "Done! Created #{batch_count} bulk reindex jobs"
puts 'Messages will be indexed shortly via the bulk_reindex_low queue'
puts '=' * 80

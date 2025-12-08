# Apply SLA Policy to Conversations
#
# This task applies an SLA policy to existing conversations that don't have one assigned.
# It processes conversations in batches and only affects conversations with sla_policy_id = nil.
#
# Usage Examples:
#   # Using arguments (may need escaping in some shells)
#   bundle exec rake "sla:apply_to_conversations[19,1,500]"
#
#   # Using environment variables (recommended)
#   SLA_POLICY_ID=19 ACCOUNT_ID=1 BATCH_SIZE=500 bundle exec rake sla:apply_to_conversations
#
# Parameters:
#   SLA_POLICY_ID: ID of the SLA policy to apply (required)
#   ACCOUNT_ID: ID of the account (required)
#   BATCH_SIZE: Number of conversations to process (default: 1000)
#
# Notes:
#   - Only runs in development environment
#   - Processes conversations in order of newest first (id DESC)
#   - Safe to run multiple times - skips conversations that already have SLA policies
#   - Creates AppliedSla records automatically via Rails callbacks
#   - SlaEvent records are created later by background jobs when violations occur
#
# rubocop:disable Metrics/BlockLength
namespace :sla do
  desc 'Apply SLA policy to existing conversations'
  task :apply_to_conversations, [:sla_policy_id, :account_id, :batch_size] => :environment do |_t, args|
    unless Rails.env.development?
      puts 'This task can only be run in the development environment.'
      puts "Current environment: #{Rails.env}"
      exit(1)
    end

    sla_policy_id = args[:sla_policy_id] || ENV.fetch('SLA_POLICY_ID', nil)
    account_id = args[:account_id] || ENV.fetch('ACCOUNT_ID', nil)
    batch_size = (args[:batch_size] || ENV['BATCH_SIZE'] || 1000).to_i

    if sla_policy_id.blank?
      puts 'Error: SLA_POLICY_ID is required'
      puts 'Usage: bundle exec rake sla:apply_to_conversations[sla_policy_id,account_id,batch_size]'
      puts 'Or: SLA_POLICY_ID=1 ACCOUNT_ID=1 BATCH_SIZE=500 bundle exec rake sla:apply_to_conversations'
      exit(1)
    end

    if account_id.blank?
      puts 'Error: ACCOUNT_ID is required'
      puts 'Usage: bundle exec rake sla:apply_to_conversations[sla_policy_id,account_id,batch_size]'
      puts 'Or: SLA_POLICY_ID=1 ACCOUNT_ID=1 BATCH_SIZE=500 bundle exec rake sla:apply_to_conversations'
      exit(1)
    end

    account = Account.find_by(id: account_id)
    unless account
      puts "Error: Account with ID #{account_id} not found"
      exit(1)
    end

    sla_policy = account.sla_policies.find_by(id: sla_policy_id)
    unless sla_policy
      puts "Error: SLA Policy with ID #{sla_policy_id} not found for Account #{account_id}"
      exit(1)
    end

    conversations = account.conversations.where(sla_policy_id: nil).order(id: :desc).limit(batch_size)
    total_count = conversations.count

    if total_count.zero?
      puts 'No conversations found without SLA policy'
      exit(0)
    end

    puts "Applying SLA Policy '#{sla_policy.name}' (ID: #{sla_policy_id}) to #{total_count} conversations in Account #{account_id}"
    puts "Processing in batches of #{batch_size}"
    puts "Started at: #{Time.current}"

    start_time = Time.current
    processed_count = 0
    error_count = 0

    conversations.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |conversation|
        conversation.update!(sla_policy_id: sla_policy_id)
        processed_count += 1
        puts "Processed #{processed_count}/#{total_count} conversations" if (processed_count % 100).zero?
      rescue StandardError => e
        error_count += 1
        puts "Error applying SLA to conversation #{conversation.id}: #{e.message}"
      end
    end

    elapsed_time = Time.current - start_time
    puts "\nCompleted!"
    puts "Successfully processed: #{processed_count} conversations"
    puts "Errors encountered: #{error_count}" if error_count.positive?
    puts "Total time: #{elapsed_time.round(2)}s"
    puts "Average time per conversation: #{(elapsed_time / processed_count).round(3)}s" if processed_count.positive?
  end
end
# rubocop:enable Metrics/BlockLength

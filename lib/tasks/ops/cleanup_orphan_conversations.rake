# frozen_string_literal: true

# Run with:
#   bundle exec rake chatwoot:ops:cleanup_orphan_conversations

namespace :chatwoot do
  namespace :ops do
    desc 'Identify and delete conversations without a valid contact or inbox in a timeframe'
    task cleanup_orphan_conversations: :environment do
      print 'Enter Account ID: '
      account_id = $stdin.gets.to_i
      account = Account.find(account_id)

      print 'Enter timeframe in days (default: 7): '
      days_input = $stdin.gets.strip
      days = days_input.empty? ? 7 : days_input.to_i

      # Build a common base relation with identical joins for OR compatibility
      base = account
             .conversations
             .where('conversations.created_at > ?', days.days.ago)
             .left_outer_joins(:contact, :inbox)

      # Find conversations whose associated contact or inbox record is missing
      conversations = base.where(contacts: { id: nil }).or(base.where(inboxes: { id: nil }))

      count = conversations.count
      puts "Found #{count} conversations without a valid contact or inbox."

      if count.positive?
        print 'Do you want to delete these conversations? (y/N): '
        confirm = $stdin.gets.strip.downcase
        if %w[y yes].include?(confirm)
          conversations.destroy_all
          puts 'Conversations deleted.'
        else
          puts 'No conversations were deleted.'
        end
      end
    end
  end
end

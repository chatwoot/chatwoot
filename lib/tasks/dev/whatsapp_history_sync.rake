namespace :dev do
  desc 'Create a WhatsApp inbox and import synthetic history through Meta-style webhook deliveries'
  task seed_whatsapp_history_sync: :environment do
    account = Account.find(ENV.fetch('ACCOUNT_ID', 1))
    result = Seeders::WhatsappHistorySyncSeeder.new(
      account: account,
      conversation_count: ENV.fetch('CONVERSATIONS', 10),
      delivery_count: ENV.fetch('DELIVERIES', 4)
    ).perform!

    puts "Inbox: #{result.inbox.name} (ID: #{result.inbox.id})"
    puts "History sync: #{result.sync.status}, #{result.sync.progress}%"
    puts "Imported: #{result.sync.imported_conversations} conversations, #{result.sync.imported_messages} messages"
    puts "Webhook deliveries: #{result.events.size}"
    puts "Open: /app/accounts/#{account.id}/settings/inboxes/#{result.inbox.id}"
  end
end

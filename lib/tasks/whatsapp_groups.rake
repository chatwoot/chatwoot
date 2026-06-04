namespace :whatsapp do
  namespace :groups do
    desc 'Backfill legacy WhatsApp group conversations from contact_inboxes source ids ending in @g.us'
    task backfill: :environment do
      batch_size = ENV.fetch('BATCH_SIZE', 100)
      inbox = Inbox.find_by(id: ENV['INBOX_ID']) if ENV['INBOX_ID'].present?
      stats = Whatsapp::GroupConversationBackfillService.new(batch_size: batch_size, inbox: inbox).perform
      puts "Backfilled #{stats[:conversations]} group conversations and #{stats[:members]} members"
    end

    desc 'Enable structured group conversations for Unoapi inboxes and backfill legacy group conversations once'
    task migrate_schema: :environment do
      batch_size = ENV.fetch('BATCH_SIZE', 100)
      stats = Whatsapp::GroupConversationSchemaMigrationService.new(batch_size: batch_size).perform
      puts "Migrated #{stats[:inboxes]} inboxes, skipped #{stats[:skipped]}, " \
           "backfilled #{stats[:conversations]} conversations and #{stats[:members]} members"
    end
  end
end

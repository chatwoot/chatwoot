# Move Inbox Rake Task
#
# Interactively moves a single inbox (and all associated records) from one
# Chatwoot account to another using Inboxes::MoveInboxToAccountService.
#
# Usage:
#   bundle exec rake inbox:move

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ModuleLength
# rubocop:disable Style/FormatStringToken
module MoveInboxTasks
  def self.prompt(message)
    print "#{message}: "
    $stdin.gets.chomp
  end

  def self.run
    puts 'Move Inbox Between Accounts'
    puts '=' * 40

    source_account = collect_source_account
    inbox = collect_inbox(source_account)
    destination_account = collect_destination_account(source_account)

    puts "\nRunning dry-run..."
    result = dry_run(source_account, inbox, destination_account)

    if result[:validation_errors].present?
      puts "\nValidation errors:"
      result[:validation_errors].each { |e| puts "  - #{e}" }
      abort "\nAborted due to validation errors."
    end

    print_preview(result)

    confirmation = prompt("\nProceed with migration? (y/N)")
    abort 'Migration cancelled.' unless confirmation.downcase == 'y'

    puts "\nExecuting migration..."
    logger = Logger.new($stdout)
    logger.formatter = proc { |_severity, _time, _progname, msg| "  #{msg}\n" }

    result = execute(source_account, inbox, destination_account, logger)

    if result[:status] == :failed
      puts "\nMigration FAILED (all changes rolled back)"
      puts "  Error: #{result[:error][:class]}: #{result[:error][:message]}"
    else
      puts "\nMigration complete!"
    end
    print_result(result)
  end

  def self.collect_source_account
    account_id = prompt("\nSource account ID")
    abort 'Error: Account ID is required' if account_id.blank?

    account = Account.find_by(id: account_id)
    abort "Error: Account ##{account_id} not found" unless account

    puts "  Account: #{account.name} (##{account.id})"
    account
  end

  def self.collect_inbox(account)
    inboxes = account.inboxes.includes(:channel).order(:id)

    abort "Error: Account ##{account.id} has no inboxes" if inboxes.empty?

    puts "\nInboxes in account ##{account.id}:"
    puts '  ID     Name                           Channel Type              Created'
    puts "  #{'-' * 80}"
    inboxes.each do |inbox|
      puts format('  %-6d %-30s %-25s %s', inbox.id, inbox.name.truncate(28), inbox.channel_type, inbox.created_at.to_date)
    end

    inbox_id = prompt("\nInbox ID to move")
    abort 'Error: Inbox ID is required' if inbox_id.blank?

    inbox = inboxes.find { |i| i.id == inbox_id.to_i }
    abort "Error: Inbox ##{inbox_id} not found in account ##{account.id}" unless inbox

    puts "  Selected: #{inbox.name} (#{inbox.channel_type})"
    inbox
  end

  def self.collect_destination_account(source_account)
    account_id = prompt("\nDestination account ID")
    abort 'Error: Account ID is required' if account_id.blank?

    abort 'Error: Destination must be different from source account' if account_id.to_i == source_account.id

    account = Account.find_by(id: account_id)
    abort "Error: Account ##{account_id} not found" unless account

    puts "  Account: #{account.name} (##{account.id})"
    account
  end

  def self.dry_run(source_account, inbox, destination_account)
    require Rails.root.join('script/move_inbox')

    Inboxes::MoveInboxToAccountService.call(
      source_account_id: source_account.id,
      source_inbox_id: inbox.id,
      destination_account_id: destination_account.id,
      dry_run: true
    )
  end

  def self.execute(source_account, inbox, destination_account, logger)
    Inboxes::MoveInboxToAccountService.call(
      source_account_id: source_account.id,
      source_inbox_id: inbox.id,
      destination_account_id: destination_account.id,
      dry_run: false,
      logger: logger
    )
  end

  def self.print_preview(result)
    will = result[:will]
    custom = result[:custom_attribute_definitions]

    puts "\nDry-run summary"
    puts '-' * 40

    inbox_info = will[:inbox] || {}
    puts "Inbox: #{inbox_info[:source_name]} (#{inbox_info[:channel_type]})"
    puts "Destination: #{inbox_info[:destination_account_name]}"

    puts "\nRecords to copy/migrate:"
    puts format('  %-30s %s', 'Labels', will[:labels])
    puts format('  %-30s %s', 'Account users', will[:account_users])
    puts format('  %-30s %s', 'Conversations', will[:conversations])
    puts format('  %-30s %s', 'Contacts', will[:contacts])
    print_contacts_to_duplicate(will[:contacts_to_duplicate])
    puts format('  %-30s %s', 'Contact inboxes', will[:contact_inboxes])
    puts format('  %-30s %s', 'Messages', will[:messages])
    puts format('  %-30s %s', 'Attachments', will[:attachments])
    puts format('  %-30s %s', 'Notes', will[:notes])
    puts format('  %-30s %s', 'CSAT responses', will[:csat_survey_responses])
    puts format('  %-30s %s', 'Mentions', will[:mentions])
    puts format('  %-30s %s', 'Reporting events', will[:reporting_events])
    puts format('  %-30s %s', 'Conversation participants', will[:conversation_participants])
    puts format('  %-30s %s', 'Inbox members', will[:inbox_members])

    puts "\nRecords to clean up (delete):"
    puts format('  %-30s %s', 'Notifications', will[:notifications])
    puts format('  %-30s %s', 'Applied SLAs', will[:applied_slas])
    puts format('  %-30s %s', 'SLA events', will[:sla_events])
    puts format('  %-30s %s', 'Agent bot inboxes', will[:agent_bot_inboxes])
    puts format('  %-30s %s', 'Inbox webhooks', will[:inbox_webhooks])
    puts format('  %-30s %s', 'Inbox hooks', will[:inbox_hooks])
    puts format('  %-30s %s', 'Campaigns', will[:campaigns])

    return if custom[:source_total].zero?

    puts "\nCustom attribute definitions:"
    puts format('  %-30s %s', 'Source total', custom[:source_total])
    puts format('  %-30s %s', 'To create', custom[:to_create])
    puts format('  %-30s %s', 'Skipped (existing)', custom[:skipped_existing])
    puts format('  %-30s %s', 'Skipped (reserved)', custom[:skipped_reserved])
  end

  def self.print_contacts_to_duplicate(contacts)
    return if contacts.blank?

    puts "\n  Contacts with conversations in other inboxes (will be duplicated):"
    puts '    ID       Name                      Email                          Phone'
    puts "    #{'-' * 75}"
    contacts.each do |c|
      puts format('    %-8s %-25s %-30s %s', c[:id], c[:name].to_s.truncate(23), c[:email].to_s.truncate(28), c[:phone_number])
    end
    puts ''
  end

  def self.print_result(result)
    moved = result[:moved]

    puts "\nFinal results (status: #{result[:status]})"
    puts '-' * 40

    puts 'Records migrated:'
    puts format('  %-30s %s', 'Labels copied', moved[:labels_copied])
    puts format('  %-30s %s', 'Account users copied', moved[:account_users_copied])
    puts format('  %-30s %s', 'Conversations', moved[:conversations])
    puts format('  %-30s %s', 'Contacts', moved[:contacts])
    puts format('  %-30s %s', 'Contacts duplicated', moved[:contacts_duplicated])
    puts format('  %-30s %s', 'Contact inboxes', moved[:contact_inboxes])
    puts format('  %-30s %s', 'Messages', moved[:messages])
    puts format('  %-30s %s', 'Attachments', moved[:attachments])
    puts format('  %-30s %s', 'Notes', moved[:notes])
    puts format('  %-30s %s', 'CSAT responses', moved[:csat_survey_responses])
    puts format('  %-30s %s', 'Mentions', moved[:mentions])
    puts format('  %-30s %s', 'Reporting events', moved[:reporting_events])
    puts format('  %-30s %s', 'Conversation participants', moved[:conversation_participants])
    puts format('  %-30s %s', 'Inbox members', moved[:inbox_members])

    puts "\nRecords cleaned up:"
    puts format('  %-30s %s', 'Notifications deleted', moved[:notifications_deleted])
    puts format('  %-30s %s', 'Applied SLAs deleted', moved[:applied_slas_deleted])
    puts format('  %-30s %s', 'SLA events deleted', moved[:sla_events_deleted])
    puts format('  %-30s %s', 'Agent bot inboxes deleted', moved[:agent_bot_inboxes_deleted])
    puts format('  %-30s %s', 'Inbox webhooks deleted', moved[:inbox_webhooks_deleted])
    puts format('  %-30s %s', 'Inbox hooks deleted', moved[:inbox_hooks_deleted])
    puts format('  %-30s %s', 'Campaigns deleted', moved[:campaigns_deleted])
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Style/FormatStringToken

namespace :inbox do
  desc 'Interactively move an inbox (and all associated records) between accounts'
  task move: :environment do
    require Rails.root.join('script/move_inbox')
    MoveInboxTasks.run
  end
end

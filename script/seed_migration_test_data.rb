# frozen_string_literal: true

# Seeds reproducible data for testing script/migrate_whatsapp_inbox_account.rb.
#
# Usage:
#   bundle exec rails runner script/seed_migration_test_data.rb
#
# Idempotent: drops accounts named "Migration Source Test" / "Migration Target Test"
# and recreates them with a WhatsApp inbox + 3 contacts + 3 conversations + messages.
#
# Designed to exercise the happy path:
# - 2 contacts that will be CLONED into target (source-only).
# - 1 contact that will be REUSED in target (pre-existing target contact with same phone).

SOURCE_NAME = 'Migration Source Test'
TARGET_NAME = 'Migration Target Test'

puts '== Cleaning up previous test accounts =='
[SOURCE_NAME, TARGET_NAME].each do |name|
  Account.where(name: name).find_each do |acct|
    puts "  - destroying account #{acct.id} (#{acct.name})"
    acct.destroy
  end
end

puts '== Creating source account =='
source_account = Account.create!(name: SOURCE_NAME)
target_account = Account.create!(name: TARGET_NAME)
puts "  source_account.id = #{source_account.id}"
puts "  target_account.id = #{target_account.id}"

puts '== Creating admin users =='
source_admin = User.create!(
  name: 'Source Admin',
  email: "source-admin-#{source_account.id}@migration.test",
  password: 'Password!123',
  confirmed_at: Time.current
)
AccountUser.create!(account: source_account, user: source_admin, role: :administrator)

target_admin = User.create!(
  name: 'Target Admin',
  email: "target-admin-#{target_account.id}@migration.test",
  password: 'Password!123',
  confirmed_at: Time.current
)
AccountUser.create!(account: target_account, user: target_admin, role: :administrator)

puts '== Creating WhatsApp inbox on source account =='
# Skip outbound HTTP from sync_templates (after_create) by suppressing the callback.
Channel::Whatsapp.skip_callback(:create, :after, :sync_templates)
channel = Channel::Whatsapp.new(
  account: source_account,
  phone_number: "+1555#{format('%07d', source_account.id)}",
  provider: 'default',
  provider_config: { 'api_key' => 'dummy-key-for-local-test' }
)
channel.save!(validate: false)
Channel::Whatsapp.set_callback(:create, :after, :sync_templates)

inbox = Inbox.create!(
  account: source_account,
  channel: channel,
  name: 'Test WhatsApp Inbox'
)
puts "  source_inbox.id = #{inbox.id}"

puts '== Creating contacts =='
# 1) Alice: source-only (will be cloned into target)
alice = Contact.create!(
  account: source_account, name: 'Alice Source', phone_number: '+15550000001'
)
# 2) Bob: matches an existing target contact by phone (will be reused)
bob_source = Contact.create!(
  account: source_account, name: 'Bob Source', email: 'bob@source.local', phone_number: '+15550000002'
)
bob_target = Contact.create!(
  account: target_account, name: 'Bob Target Pre-existing', phone_number: '+15550000002'
)
# 3) Carol: source-only (will be cloned into target)
carol = Contact.create!(
  account: source_account, name: 'Carol Source', phone_number: '+15550000003'
)
puts "  alice=#{alice.id} bob_source=#{bob_source.id} bob_target=#{bob_target.id} carol=#{carol.id}"

# Silence Message#send_reply during the seed because the dummy provider_config above
# would otherwise cause Sidekiq's SendReplyJob to hit the real Meta API, fail with 404
# and mark every outgoing message as failed. The migration script bypasses this
# callback entirely (it uses update_all), so the production behavior is unaffected.
Message.define_method(:send_reply) { nil }

puts '== Linking contacts to inbox (ContactInbox) and creating conversations =='
# rubocop:disable Metrics/BlockLength
[alice, bob_source, carol].each_with_index do |contact, idx|
  ci = ContactInbox.create!(
    contact: contact,
    inbox: inbox,
    source_id: contact.phone_number.delete('^0-9')
  )

  conv = Conversation.create!(
    account: source_account,
    inbox: inbox,
    contact: contact,
    contact_inbox: ci,
    status: :open,
    additional_attributes: { 'seed_index' => idx }
  )

  # Incoming message from contact
  Message.create!(
    account: source_account,
    inbox: inbox,
    conversation: conv,
    message_type: :incoming,
    content: "Hello from #{contact.name}",
    sender: contact
  )

  # Outgoing message from admin
  outgoing = Message.create!(
    account: source_account,
    inbox: inbox,
    conversation: conv,
    message_type: :outgoing,
    content: "Reply to #{contact.name}",
    sender: source_admin
  )
  # Simulate a successful delivery: outgoing messages enter the table as `sent` by default.
  # Bumping to `delivered` keeps the fixture realistic for a typical post-delivery state.
  outgoing.update_columns(status: Message.statuses[:delivered]) # rubocop:disable Rails/SkipsModelValidations

  # Attach a tiny inline file to the first conversation to exercise attachment remap
  next unless idx.zero?

  outgoing.attachments.create!(
    account_id: source_account.id,
    file_type: :file
  )
end
# rubocop:enable Metrics/BlockLength

puts ''
puts '== Done =='
puts "Source account id: #{source_account.id}"
puts "Source inbox id:   #{inbox.id}"
puts "Target account id: #{target_account.id}"
puts ''
puts 'Next step (dry-run):'
puts '  bundle exec rails runner script/migrate_whatsapp_inbox_account.rb \\'
puts "    --source-inbox-id=#{inbox.id} --target-account-id=#{target_account.id} --mode=dry-run"

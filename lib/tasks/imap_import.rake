# frozen_string_literal: true

require 'net/imap'
require 'concurrent'

def connect_imap(channel, folder)
  imap = Net::IMAP.new(channel.imap_address, port: channel.imap_port, ssl: channel.imap_enable_ssl, open_timeout: 30)

  if channel.google?
    token = Google::RefreshOauthTokenService.new(channel: channel).access_token
    imap.authenticate('XOAUTH2', channel.imap_login, token)
  elsif channel.microsoft?
    token = Microsoft::RefreshOauthTokenService.new(channel: channel).access_token
    imap.authenticate('XOAUTH2', channel.imap_login, token)
  else
    imap.authenticate('PLAIN', channel.imap_login, channel.imap_password)
  end

  imap.select(folder)
  imap
end

def format_duration(seconds)
  seconds = seconds.to_i
  if seconds < 60
    "#{seconds}s"
  elsif seconds < 3600
    "#{seconds / 60}m#{seconds % 60}s"
  else
    "#{seconds / 3600}h#{(seconds % 3600) / 60}m"
  end
end

def validate_inbox(inbox_id)
  inbox = Inbox.find_by(id: inbox_id)
  abort "ERROR: Inbox #{inbox_id} not found." unless inbox

  channel = inbox.channel
  abort "ERROR: Inbox #{inbox_id} is not an email channel." unless channel.is_a?(Channel::Email)
  abort "ERROR: IMAP is not enabled for inbox #{inbox_id}." unless channel.imap_enabled?

  [inbox, channel]
end

def scan_new_email_uids(imap, channel, uids)
  new_uids = []
  skipped = 0

  uids.each_slice(100) do |batch|
    headers = imap.uid_fetch(batch, 'BODY.PEEK[HEADER.FIELDS (MESSAGE-ID)]')
    next if headers.blank?

    headers.each do |data|
      msg_id = Mail.read_from_string(data.attr['BODY[HEADER.FIELDS (MESSAGE-ID)]']).message_id
      if msg_id.blank? || channel.inbox.messages.exists?(source_id: msg_id)
        skipped += 1
      else
        new_uids << data.attr['UID']
      end
    end

    print "\r  Scanning headers... #{new_uids.size} new, #{skipped} skipped (#{new_uids.size + skipped}/#{uids.size})   "
  end

  puts ''
  [new_uids, skipped]
end

def import_single_email(imap, channel, uid)
  mail_data = imap.uid_fetch(uid, 'RFC822')
  return false if mail_data.blank?

  mail_str = mail_data[0].attr['RFC822']
  return false if mail_str.blank?

  inbound_mail = Mail.read_from_string(mail_str)
  Imap::ImapMailbox.new.process(inbound_mail, channel)

  # Backdate message created_at to the original email date
  backdate_message(channel, inbound_mail) if inbound_mail.date.present?
  true
end

def backdate_message(channel, inbound_mail)
  message = channel.inbox.messages.find_by(source_id: inbound_mail.message_id)
  return unless message

  original_date = inbound_mail.date.to_datetime
  message.update_columns(created_at: original_date) # rubocop:disable Rails/SkipsModelValidations
end

# Fixes conversation timestamps after all messages are imported.
# Must run after import to avoid after_create_commit callbacks overwriting values.
def backdate_conversations(inbox)
  puts 'Backdating conversation timestamps...'
  count = 0

  inbox.conversations.find_each do |conversation|
    oldest = conversation.messages.minimum(:created_at)
    newest = conversation.messages.maximum(:created_at)
    next unless oldest

    conversation.update_columns( # rubocop:disable Rails/SkipsModelValidations
      created_at: oldest,
      last_activity_at: newest,
      agent_last_seen_at: newest,
      status: :resolved
    )
    count += 1
  end

  puts "  Updated #{count} conversations."
end

def import_worker(channel, folder, uid_batch, progress) # rubocop:disable Metrics/MethodLength
  ActiveRecord::Base.connection_pool.with_connection do
    imap = connect_imap(channel, folder)
    begin
      uid_batch.each do |uid|
        import_single_email(imap, channel, uid)

        progress[:mutex].synchronize do
          progress[:imported] += 1
          print_import_progress(progress)
        end
      rescue StandardError => e
        progress[:mutex].synchronize do
          progress[:errors] += 1
          print_import_progress(progress)
        end
        warn "\n  [ERROR] uid #{uid}: #{e.message}"
      end
    ensure
      imap&.logout
    end
  end
rescue StandardError => e
  warn "\n  [WORKER ERROR] #{e.message}"
end

def print_import_progress(progress)
  processed = progress[:imported] + progress[:skipped] + progress[:errors]
  total = progress[:total]
  pct = ((processed.to_f / total) * 100).round(1)
  elapsed = Time.zone.now - progress[:started_at]
  rate = processed.positive? ? (elapsed / processed) : 0
  eta = rate.positive? ? ((total - processed) * rate) : 0

  print "\r  [#{pct}%] #{processed}/#{total} | imported: #{progress[:imported]} | " \
        "skipped: #{progress[:skipped]} | errors: #{progress[:errors]} | " \
        "elapsed: #{format_duration(elapsed)} | ETA: #{format_duration(eta)}   "
end

namespace :imap do # rubocop:disable Metrics/BlockLength
  desc 'Import all historical emails from IMAP into a Chatwoot inbox'
  task :import, %i[inbox_id days folder workers] => :environment do |_task, args| # rubocop:disable Metrics/BlockLength
    inbox_id = args[:inbox_id]
    days = (args[:days] || 7).to_i
    folder = args[:folder] || 'INBOX'
    workers = (args[:workers] || 4).to_i

    if inbox_id.blank?
      puts 'Usage: rails imap:import[<inbox_id>,<days>,<folder>,<workers>]'
      puts '  days:    how far back to look (default: 7)'
      puts '  folder:  IMAP folder (default: INBOX)'
      puts '  workers: parallel connections (default: 4)'
      puts ''
      puts 'Tip: set RAILS_MAX_THREADS above worker count to avoid DB pool exhaustion:'
      puts '  RAILS_MAX_THREADS=10 bundle exec rails imap:import[81,3650,INBOX,8]'
      next
    end

    inbox, channel = validate_inbox(inbox_id)

    puts "Inbox:    #{inbox.name} (ID: #{inbox.id})"
    puts "Email:    #{channel.email}"
    puts "Server:   #{channel.imap_address}:#{channel.imap_port}"
    puts "Folder:   #{folder}"
    puts "Lookback: #{days} days"
    puts "Workers:  #{workers}"
    puts '-' * 60

    # Phase 1: scan headers with a single connection to find new emails
    imap = connect_imap(channel, folder)
    since_date = (Time.zone.today - days).strftime('%d-%b-%Y')

    puts "Searching emails since #{since_date}..."
    uids = imap.uid_search(['SINCE', since_date])
    puts "Found #{uids.length} emails in #{folder}."

    new_uids, skipped = scan_new_email_uids(imap, channel, uids)
    imap.logout

    if new_uids.empty?
      puts 'Nothing new to import.'
      next
    end

    puts "Importing #{new_uids.size} emails with #{workers} parallel workers..."
    progress = {
      imported: 0, skipped: skipped, errors: 0,
      total: new_uids.size + skipped, mutex: Mutex.new, started_at: Time.zone.now
    }

    # Phase 2: split work across N threads, each with its own IMAP connection
    chunks = new_uids.each_slice((new_uids.size.to_f / workers).ceil).to_a
    threads = chunks.map do |chunk|
      Thread.new { import_worker(channel, folder, chunk, progress) }
    end
    threads.each(&:join)

    # Phase 3: fix conversation timestamps after all callbacks have settled
    backdate_conversations(inbox)

    elapsed = Time.zone.now - progress[:started_at]

    puts ''
    puts '=' * 60
    puts 'Import complete!'
    puts "  Imported: #{progress[:imported]}"
    puts "  Skipped:  #{progress[:skipped]} (already present)"
    puts "  Errors:   #{progress[:errors]}"
    puts "  Time:     #{format_duration(elapsed)}"
    puts '=' * 60
  end
end

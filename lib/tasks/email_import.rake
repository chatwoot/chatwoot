# Import historical emails from IMAP in date-range batches
#
# This task imports historical emails from an email inbox's IMAP server.
# It processes emails in batches by date range, from oldest to newest,
# to ensure proper email threading.
#
# Usage Examples:
#   # Basic usage - import last year
#   INBOX_ID=123 bundle exec rake chatwoot:email:import_historical
#
#   # Import from a specific date
#   INBOX_ID=123 START_DATE=2021-01-01 bundle exec rake chatwoot:email:import_historical
#
#   # Resume from a specific batch
#   INBOX_ID=123 START_DATE=2021-01-01 RESUME_BATCH=50 bundle exec rake chatwoot:email:import_historical
#
#   # Import and resolve old conversations
#   INBOX_ID=123 START_DATE=2021-01-01 RESOLVE_BEFORE=2024-01-01 bundle exec rake chatwoot:email:import_historical
#
# Parameters (via environment variables):
#   INBOX_ID: ID of the email inbox (required)
#   START_DATE: ISO date (YYYY-MM-DD) to import from (default: 1 year ago)
#   BATCH_SIZE: Days per batch (default: 10)
#   RESUME_BATCH: Batch number to resume from, 0-indexed (default: 0)
#   DELAY_BETWEEN_BATCHES: Seconds between batches (default: 2)
#   RESOLVE_BEFORE: ISO date (YYYY-MM-DD) - resolve all conversations created before this date
#
# Notes:
#   - Only works with Channel::Email inboxes with IMAP enabled
#   - Processes from oldest to newest for proper email threading
#   - Skips already imported emails (based on message_id)
#   - Continues processing even if individual batches fail
#   - Provides ETA and progress updates
#
require 'net/imap'

# rubocop:disable Metrics/BlockLength
namespace :chatwoot do
  namespace :email do
    desc 'Import historical emails from IMAP in date-range batches'
    task import_historical: :environment do
      inbox_id = ENV.fetch('INBOX_ID', nil)
      start_date_str = ENV.fetch('START_DATE', nil)
      batch_size = (ENV['BATCH_SIZE'] || 10).to_i
      resume_batch = (ENV['RESUME_BATCH'] || 0).to_i
      delay_between_batches = (ENV['DELAY_BETWEEN_BATCHES'] || 2).to_i
      resolve_before = ENV.fetch('RESOLVE_BEFORE', nil)

      if inbox_id.blank?
        puts 'Error: INBOX_ID is required'
        puts 'Usage: INBOX_ID=123 bundle exec rake chatwoot:email:import_historical'
        puts ''
        puts 'Optional parameters:'
        puts '  START_DATE=YYYY-MM-DD      Date to import from (default: 1 year ago)'
        puts '  BATCH_SIZE=10              Days per batch'
        puts '  RESUME_BATCH=0             Batch number to resume from'
        puts '  DELAY_BETWEEN_BATCHES=2    Seconds between batches'
        puts '  RESOLVE_BEFORE=YYYY-MM-DD  Resolve conversations created before this date'
        exit(1)
      end

      inbox = Inbox.find_by(id: inbox_id)

      unless inbox
        puts "Error: Inbox with ID #{inbox_id} not found"
        exit(1)
      end

      unless inbox.channel_type == 'Channel::Email'
        puts "Error: Inbox #{inbox_id} is not an email inbox (type: #{inbox.channel_type})"
        exit(1)
      end

      channel = inbox.channel

      unless channel.imap_enabled
        puts "Error: IMAP is not enabled for inbox #{inbox_id}"
        exit(1)
      end

      if channel.reauthorization_required?
        puts 'Error: Channel requires reauthorization!'
        puts "Run: channel = Inbox.find(#{inbox_id}).channel; channel.prompt_reauthorization!"
        exit(1)
      end

      start_date = if start_date_str.present?
                     begin
                       Date.parse(start_date_str)
                     rescue ArgumentError
                       puts "Error: Invalid date format for START_DATE: #{start_date_str}"
                       puts 'Expected format: YYYY-MM-DD (e.g., 2021-01-01)'
                       exit(1)
                     end
                   else
                     Time.zone.today - 365
                   end

      total_days = (Time.zone.today - start_date).to_i
      if total_days <= 0
        puts "Error: START_DATE must be in the past (got: #{start_date})"
        exit(1)
      end

      resolve_before_date = nil
      if resolve_before.present?
        begin
          resolve_before_date = Date.parse(resolve_before)
        rescue ArgumentError
          puts "Error: Invalid date format for RESOLVE_BEFORE: #{resolve_before}"
          puts 'Expected format: YYYY-MM-DD (e.g., 2024-01-01)'
          exit(1)
        end
      end

      puts '=' * 80
      puts 'Email Import Task'
      puts '=' * 80
      puts ''
      puts 'Inbox Details:'
      puts "  ID: #{inbox.id}"
      puts "  Name: #{inbox.name}"
      puts "  Account: #{inbox.account.name} (ID: #{inbox.account_id})"
      puts "  Email: #{channel.email}"
      puts "  Provider: #{channel.provider}"
      puts ''

      num_batches = (total_days.to_f / batch_size).ceil

      puts 'Import Configuration:'
      puts "  Start date: #{start_date}"
      puts "  Days to import: #{total_days}"
      puts "  Batch size: #{batch_size} days"
      puts "  Total batches: #{num_batches}"
      puts "  Resuming from batch: #{resume_batch + 1}" if resume_batch.positive?
      puts "  Batches to process: #{num_batches - resume_batch}"
      puts "  Delay between batches: #{delay_between_batches} seconds"
      puts "  Resolve before: #{resolve_before_date || 'disabled'}"
      puts ''

      messages_before = inbox.messages.where(content_type: 'incoming_email').count
      puts "Messages before import: #{messages_before}"
      puts ''

      puts 'Starting batched import...'
      overall_start_time = Time.current
      puts "Started at: #{overall_start_time}"
      puts '-' * 80
      puts ''

      successful_batches = 0
      failed_batches = []
      total_new_messages = 0
      batch_times = []

      (resume_batch...num_batches).each do |batch_num|
        batch_start_days_ago = total_days - (batch_num * batch_size)
        batch_end_days_ago = [batch_start_days_ago - batch_size, 0].max

        batch_start_date = (Time.zone.today - batch_start_days_ago).strftime('%d-%b-%Y')
        batch_end_date = (Time.zone.today - batch_end_days_ago).strftime('%d-%b-%Y')

        puts "[Batch #{batch_num + 1}/#{num_batches}] #{batch_start_date} to #{batch_end_date} " \
             "(#{batch_start_days_ago}-#{batch_end_days_ago} days ago)"

        begin
          batch_start_time = Time.current

          imap_client = build_imap_client(channel)

          search_criteria = if batch_end_days_ago.zero?
                              ['SINCE', batch_start_date]
                            else
                              next_day = (Time.zone.today - batch_end_days_ago + 1).strftime('%d-%b-%Y')
                              ['SINCE', batch_start_date, 'BEFORE', next_day]
                            end

          seq_nums = imap_client.search(search_criteria)
          puts "  Found #{seq_nums.length} emails in date range"

          if seq_nums.empty?
            puts '  ✓ No emails in this range, skipping'
            safely_disconnect_imap(imap_client)
            successful_batches += 1
            sleep delay_between_batches unless batch_num == num_batches - 1
            next
          end

          message_ids_with_seq = []
          seq_nums.each_slice(10) do |batch|
            batch_message_ids = imap_client.fetch(batch, 'BODY.PEEK[HEADER]')
            next if batch_message_ids.blank?

            batch_message_ids.each do |data|
              message_id = Mail.read_from_string(data.attr['BODY[HEADER]']).message_id
              message_ids_with_seq.push([data.seqno, message_id])
            end
          end

          new_count = process_email_batch(channel, imap_client, message_ids_with_seq)
          total_new_messages += new_count

          safely_disconnect_imap(imap_client)

          batch_duration = Time.current - batch_start_time
          batch_times << batch_duration
          current_message_count = inbox.messages.where(content_type: 'incoming_email').count

          elapsed_time = Time.current - overall_start_time
          avg_batch_time = batch_times.sum / batch_times.length
          remaining_batches = num_batches - batch_num - 1
          eta_seconds = remaining_batches * avg_batch_time
          eta_minutes = (eta_seconds / 60).round(1)

          puts "  ✓ Completed in #{batch_duration.round(2)}s"
          puts "  New messages in batch: #{new_count}"
          puts "  Total messages now: #{current_message_count}"
          puts "  Elapsed: #{(elapsed_time / 60).round(1)}m | ETA: #{eta_minutes}m (#{remaining_batches} batches remaining)"
          puts ''

          successful_batches += 1
          sleep delay_between_batches unless batch_num == num_batches - 1

        rescue StandardError => e
          puts "  ✗ ERROR in batch #{batch_num + 1}:"
          puts "    #{e.class}: #{e.message}"
          puts ''
          puts e.backtrace.first(5).join("\n") if e.backtrace
          failed_batches << { batch: batch_num + 1, start_date: batch_start_date, end_date: batch_end_date, error: e.message }

          safely_disconnect_imap(imap_client) if defined?(imap_client) && imap_client
          sleep delay_between_batches unless batch_num == num_batches - 1
        end
      end

      puts ''
      puts '-' * 80
      puts 'Import completed!'
      puts "Completed at: #{Time.current}"
      puts ''

      resolved_count = 0
      if resolve_before_date
        puts 'Resolving old conversations...'
        conversations_to_resolve = inbox.conversations
                                        .where(status: :open)
                                        .where('created_at < ?', resolve_before_date.beginning_of_day)
        resolved_count = conversations_to_resolve.count
        conversations_to_resolve.update_all(status: :resolved) # rubocop:disable Rails/SkipsModelValidations
        puts "  ✓ Resolved #{resolved_count} conversations created before #{resolve_before_date}"
        puts ''
      end

      messages_after = inbox.messages.where(content_type: 'incoming_email').count
      puts 'Summary:'
      puts "  Successful batches: #{successful_batches}/#{num_batches - resume_batch}"
      puts "  Failed batches: #{failed_batches.count}"
      puts "  Messages before: #{messages_before}"
      puts "  Messages after: #{messages_after}"
      puts "  New messages imported: #{messages_after - messages_before}"
      puts "  Conversations resolved: #{resolved_count}" if resolve_before_date
      puts "  Total conversations: #{inbox.conversations.count}"

      if failed_batches.any?
        puts ''
        puts 'Failed Batches:'
        failed_batches.each do |failure|
          puts "  Batch #{failure[:batch]} (#{failure[:start_date]} to #{failure[:end_date]}): #{failure[:error]}"
        end
      end

      puts ''
      puts '=' * 80
      puts 'Done!'
      puts '=' * 80
    end

    def build_imap_client(channel)
      ssl_options = if Rails.env.development?
                      { verify_mode: OpenSSL::SSL::VERIFY_NONE }
                    else
                      true
                    end
      imap = Net::IMAP.new(channel.imap_address, port: channel.imap_port, ssl: ssl_options)

      if channel.microsoft? || channel.google?
        imap.authenticate('XOAUTH2', channel.imap_login, channel.provider_config['access_token'])
      else
        imap.login(channel.imap_login, channel.imap_password)
      end

      imap.select('INBOX')
      imap
    end

    def safely_disconnect_imap(imap_client)
      imap_client.logout
    rescue StandardError
      imap_client.disconnect
    end

    def process_email_batch(channel, imap_client, message_ids_with_seq)
      mailbox = Imap::ImapMailbox.new
      processed_count = 0

      message_ids_with_seq.each do |seq_no, message_id|
        next if message_id.blank?
        next if channel.inbox.messages.find_by(source_id: message_id).present?

        begin
          mail_str = imap_client.fetch(seq_no, 'RFC822')[0].attr['RFC822']
          next if mail_str.blank?

          inbound_mail = Mail.read_from_string(mail_str)
          mailbox.process(inbound_mail, channel)
          processed_count += 1
        rescue StandardError => e
          Rails.logger.error "[Email Import] Error processing message #{message_id}: #{e.message}"
        end
      end

      processed_count
    end
  end
end
# rubocop:enable Metrics/BlockLength

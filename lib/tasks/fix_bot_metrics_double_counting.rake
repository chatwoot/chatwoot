# frozen_string_literal: true

namespace :bot_metrics do
  desc 'Diagnose double-counted bot reporting events (conversations with both handoff and bot_resolved)'
  task diagnose: :environment do
    BotMetricsDiagnostic.new.run
  end
end

class BotMetricsDiagnostic
  def run
    print_header
    account = prompt_account
    range = prompt_date_range
    run_diagnostic(account, range)
  end

  private

  def print_header
    puts ''
    puts color('=' * 70, :cyan)
    puts color('Bot Metrics Diagnostic', :bold, :cyan)
    puts color('=' * 70, :cyan)
    puts 'This task checks for conversations that have both conversation_bot_handoff'
    puts 'AND conversation_bot_resolved events within the same date range, which can'
    puts 'cause handoff_rate + resolution_rate to exceed 100%.'
    puts ''
    puts 'No data is modified — this is read-only.'
    puts ''
  end

  def prompt_account
    print 'Enter Account ID: '
    account_id = $stdin.gets.chomp
    abort color('Error: Account ID is required', :red, :bold) if account_id.blank?

    account = Account.find_by(id: account_id)
    abort color("Error: Account with ID #{account_id} not found", :red, :bold) unless account

    puts color("Found account: #{account.name} (ID: #{account.id})", :gray)
    puts ''
    account
  end

  def prompt_date_range
    print 'Start date (YYYY-MM-DD, default: 30 days ago): '
    start_input = $stdin.gets.chomp
    start_date = start_input.present? ? Time.zone.parse(start_input) : 30.days.ago.beginning_of_day

    print 'End date (YYYY-MM-DD, default: today): '
    end_input = $stdin.gets.chomp
    end_date = end_input.present? ? Time.zone.parse(end_input).end_of_day : Time.zone.now

    puts color("Date range: #{start_date.to_date} to #{end_date.to_date}", :gray)
    puts ''
    start_date...end_date
  end

  def run_diagnostic(account, range)
    @range = range
    bot_inbox_ids = account.inboxes.select(&:active_bot?).map(&:id)
    bot_conversations = account.conversations.where(inbox_id: bot_inbox_ids, created_at: range)

    handoff_conv_ids = account.reporting_events
                              .where(name: 'conversation_bot_handoff', created_at: range)
                              .distinct.pluck(:conversation_id)

    resolved_conv_ids = account.reporting_events
                               .where(name: 'conversation_bot_resolved', created_at: range)
                               .distinct.pluck(:conversation_id)

    overlap_ids = handoff_conv_ids & resolved_conv_ids

    print_overview(bot_conversations, handoff_conv_ids, resolved_conv_ids, overlap_ids)
    print_rate_comparison(bot_conversations, handoff_conv_ids, resolved_conv_ids, overlap_ids)
    print_samples(account, overlap_ids.first(5)) if overlap_ids.any?
  end

  def print_overview(bot_conversations, handoff_conv_ids, resolved_conv_ids, overlap_ids)
    puts color('=' * 70, :yellow)
    puts color('Overview', :bold, :yellow)
    puts color('=' * 70, :yellow)
    puts "Bot conversations in range:             #{bot_conversations.count}"
    puts "Conversations with bot_handoff event:    #{handoff_conv_ids.count}"
    puts "Conversations with bot_resolved event:   #{resolved_conv_ids.count}"
    puts color("Conversations with BOTH in range:        #{overlap_ids.count}", overlap_ids.any? ? :red : :green, :bold)
    puts ''
  end

  def print_rate_comparison(bot_conversations, handoff_conv_ids, resolved_conv_ids, overlap_ids)
    conv_count = bot_conversations.count

    puts color('=' * 70, :cyan)
    puts color('Rate Comparison', :bold, :cyan)
    puts color('=' * 70, :cyan)

    if conv_count.zero?
      puts 'No bot conversations in range — rates are 0%.'
      puts ''
      return
    end

    old_resolution_rate, handoff_rate, new_resolution_rate = rate_comparison(
      handoff_conv_ids, resolved_conv_ids, overlap_ids, conv_count
    )

    puts '                     Resolution %    Handoff %    Sum'
    puts color(rate_row('Before fix:', old_resolution_rate, handoff_rate), rate_color(old_resolution_rate, handoff_rate))
    puts color(rate_row('After fix:', new_resolution_rate, handoff_rate), :green)
    puts ''
  end

  def percentage(count, total)
    (count.to_f / total * 100).to_i
  end

  def rate_comparison(handoff_conv_ids, resolved_conv_ids, overlap_ids, conv_count)
    [
      percentage(resolved_conv_ids.count, conv_count),
      percentage(handoff_conv_ids.count, conv_count),
      percentage((resolved_conv_ids - overlap_ids).count, conv_count)
    ]
  end

  def rate_row(label, resolution_rate, handoff_rate)
    "  #{label.ljust(18)}#{resolution_rate.to_s.rjust(10)}    #{handoff_rate.to_s.rjust(8)}    #{resolution_rate + handoff_rate}%"
  end

  def rate_color(resolution_rate, handoff_rate)
    resolution_rate + handoff_rate > 100 ? :red : :gray
  end

  def print_samples(account, conv_ids)
    puts color('Sample overlapping conversations:', :bold, :cyan)
    puts ''

    conv_ids.each do |conv_id|
      conversation = account.conversations.find_by(id: conv_id)
      next unless conversation

      resolved_event = account.reporting_events.find_by(conversation_id: conv_id, name: 'conversation_bot_resolved', created_at: @range)
      handoff_event = account.reporting_events.find_by(conversation_id: conv_id, name: 'conversation_bot_handoff', created_at: @range)

      puts "  Conversation ##{conversation.display_id} (id: #{conv_id})"
      puts "    Inbox: #{conversation.inbox&.name || 'N/A'} | Status: #{conversation.status}"
      puts "    bot_resolved created_at:  #{resolved_event&.created_at}"
      puts "    bot_handoff created_at:   #{handoff_event&.created_at}"
      puts ''
    end
  end

  ANSI_COLORS = {
    reset: "\e[0m",
    bold: "\e[1m",
    red: "\e[31m",
    green: "\e[32m",
    yellow: "\e[33m",
    cyan: "\e[36m",
    gray: "\e[90m"
  }.freeze

  def color(text, *styles)
    return text unless $stdout.tty?

    codes = styles.filter_map { |style| ANSI_COLORS[style] }.join
    "#{codes}#{text}#{ANSI_COLORS[:reset]}"
  end
end

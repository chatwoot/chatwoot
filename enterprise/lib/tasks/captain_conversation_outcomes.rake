# frozen_string_literal: true

namespace :captain do
  namespace :conversation_outcomes do
    desc 'Interactively backfill Captain conversation outcomes for recently active conversations'
    task backfill: :environment do
      CaptainConversationOutcomesBackfillTask.new.run
    end
  end
end

class CaptainConversationOutcomesBackfillTask # rubocop:disable Metrics/ClassLength
  ACTIVITY_DAYS = 60
  BATCH_SIZE = 100

  ANSI_COLORS = {
    reset: "\e[0m",
    bold: "\e[1m",
    red: "\e[31m",
    green: "\e[32m",
    yellow: "\e[33m",
    cyan: "\e[36m",
    gray: "\e[90m"
  }.freeze

  def run
    print_header
    account = prompt_account
    assistants = account.captain_assistants.includes(:captain_inboxes).order(:id).to_a
    return print_no_assistants(account) if assistants.empty?

    cutoff = ACTIVITY_DAYS.days.ago
    plans = build_plans(assistants, cutoff)
    print_plan(account, plans, cutoff)
    process_assistants(plans, cutoff)
    print_overall_summary(account)
  end

  private

  def print_header
    puts ''
    puts color('=' * 78, :cyan)
    puts color('Captain Conversation Outcomes Backfill', :bold, :cyan)
    puts color('=' * 78, :cyan)
    puts color('What this task does:', :bold, :yellow)
    puts "- Finds conversations with activity in the last #{ACTIVITY_DAYS} days."
    puts '- Requires a message or agent session attributable to the assistant.'
    puts '- Reconstructs the selected conversation from its complete historical timeline.'
    puts '- Skips conversations that already have any outcome records.'
    puts '- Preserves historical handoffs, but leaves their reason category unclassified.'
    puts '- Requests confirmation separately for every assistant before writing.'
    puts ''
  end

  def prompt_account
    print 'Enter Account ID: '
    account_id = $stdin.gets.to_s.strip
    abort color('Error: Account ID is required', :red, :bold) if account_id.blank?

    account = Account.find_by(id: account_id)
    abort color("Error: Account with ID #{account_id} not found", :red, :bold) unless account

    puts color("Found account: #{account.name} (ID: #{account.id})", :gray)
    puts ''
    account
  end

  def build_plans(assistants, cutoff)
    puts color('Discovering candidate conversations...', :gray)

    plans = assistants.map do |assistant|
      candidate_count = candidate_scope(assistant, cutoff).count
      print '.'
      $stdout.flush
      { assistant: assistant, candidate_count: candidate_count }
    end
    puts "\n\n"
    plans
  end

  def print_plan(account, plans, cutoff)
    puts color('Backfill plan', :bold, :cyan)
    puts color('-' * 78, :cyan)
    print_plan_metadata(account, cutoff)
    print_plan_table(plans)
    print_plan_footer(plans)
  end

  def print_plan_metadata(account, cutoff)
    puts "Account:          #{account.name} (ID: #{account.id})"
    puts "Activity cutoff:  #{cutoff.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "Batch size:       #{BATCH_SIZE} conversations"
    puts ''
  end

  def print_plan_table(plans)
    puts '  ID         Assistant                               Inboxes   Candidates'
    puts "  #{'-' * 72}"
    plans.each do |plan|
      assistant = plan[:assistant]
      puts format(
        '  %<id>-10s %<name>-36s %<inboxes>10d %<candidates>12d',
        id: assistant.id,
        name: truncate(assistant.name, 36),
        inboxes: assistant.captain_inboxes.size,
        candidates: plan[:candidate_count]
      )
    end
    puts ''
  end

  def print_plan_footer(plans)
    puts color("Total candidate assignments: #{plans.sum { |plan| plan[:candidate_count] }}", :bold)
    puts color('Counts can overlap when a conversation has evidence from more than one assistant; those conversations are skipped.', :gray)
    puts color('-' * 78, :cyan)
    puts ''
  end

  def process_assistants(plans, cutoff)
    @overall = empty_summary

    plans.each_with_index do |plan, index|
      assistant = plan[:assistant]
      scope = candidate_scope(assistant, cutoff)
      candidate_count = scope.count

      print_assistant_header(assistant, candidate_count, index + 1, plans.size)
      if candidate_count.zero?
        puts ''
        next
      end

      choice = prompt_assistant
      break if choice == :quit
      next unless choice == :process

      summary = process_assistant(assistant, scope, candidate_count)
      merge_overall(summary)
      print_assistant_summary(summary)
    end
  end

  def print_assistant_header(assistant, candidate_count, position, total)
    puts color("Assistant #{position}/#{total}", :bold, :cyan)
    puts "  Name:       #{assistant.name}"
    puts "  ID:         #{assistant.id}"
    puts "  Candidates: #{candidate_count}"
    puts ''

    puts color('  Nothing to backfill.', :gray) if candidate_count.zero?
  end

  def prompt_assistant
    print 'Process this assistant? ([y]es / [n]o / [q]uit): '

    case $stdin.gets.to_s.strip.downcase
    when 'y', 'yes'
      :process
    when 'q', 'quit'
      puts color("\nStopping before the remaining assistants.\n", :yellow)
      :quit
    else
      puts color("Skipped by operator.\n", :yellow)
      :skip
    end
  end

  def process_assistant(assistant, scope, candidate_count)
    summary = empty_summary.merge(assistants_processed: 1, candidates: candidate_count)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    puts color('Processing conversations...', :gray)
    scope.in_batches(of: BATCH_SIZE) do |batch|
      results = Captain::ConversationOutcomeBackfillService.new(
        assistant: assistant,
        conversation_ids: batch.pluck(:id)
      ).perform

      results.each { |result| record_result(summary, result) }
      print_progress(summary, candidate_count)
    end

    summary[:elapsed] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    puts "\n"
    summary
  end

  def record_result(summary, result)
    summary[:processed] += 1

    case result.status
    when :created
      summary[:backfilled] += 1
      summary[:episodes] += result.episode_count
    when :skipped
      summary[:skipped][result.reason] += 1
    when :failed
      summary[:failures] << result
    end
  end

  def print_progress(summary, total)
    percentage = total.zero? ? 100 : (summary[:processed].to_f / total * 100).round(1)
    message = [
      "  #{summary[:processed]}/#{total} (#{percentage}%)",
      "backfilled: #{summary[:backfilled]}",
      "episodes: #{summary[:episodes]}",
      "skipped: #{summary[:skipped].values.sum}",
      "failed: #{summary[:failures].size}"
    ].join(' | ')
    print "\r#{message.ljust(100)}"
    $stdout.flush
  end

  def print_assistant_summary(summary)
    status_color = summary[:failures].empty? ? :green : :yellow
    puts color('-' * 78, status_color)
    puts color('Assistant complete', :bold, status_color)
    print_summary_counts(summary)
    puts "  Elapsed time:             #{summary[:elapsed].round(2)} seconds"
    print_skip_breakdown(summary[:skipped])
    print_failures(summary[:failures])
    puts color('-' * 78, status_color)
    puts ''
  end

  def print_summary_counts(summary)
    puts "  Conversations inspected: #{summary[:processed]}"
    puts "  Conversations backfilled: #{summary[:backfilled]}"
    puts "  Episodes created:          #{summary[:episodes]}"
    puts "  Conversations skipped:    #{summary[:skipped].values.sum}"
    puts "  Failures:                 #{summary[:failures].size}"
  end

  def print_skip_breakdown(skipped)
    return if skipped.empty?

    puts ''
    puts color('  Skip reasons:', :yellow)
    skipped.sort_by { |reason, _count| reason.to_s }.each do |reason, count|
      puts "    - #{reason.to_s.humanize}: #{count}"
    end
  end

  def print_failures(failures)
    return if failures.empty?

    puts ''
    puts color('  Failed conversations:', :red, :bold)
    failures.each do |result|
      puts "    - #{result.conversation_id}: #{result.error.class.name} - #{result.error.message}"
    end
  end

  def print_overall_summary(account)
    status_color = @overall[:failures].empty? ? :green : :yellow
    puts color('=' * 78, status_color)
    puts color('BACKFILL SESSION COMPLETE', :bold, status_color)
    puts color('=' * 78, status_color)
    puts "Account:                   #{account.name} (ID: #{account.id})"
    print_overall_counts
    puts color('=' * 78, status_color)
  end

  def print_overall_counts
    puts "Assistants processed:      #{@overall[:assistants_processed]}"
    puts "Conversations inspected:   #{@overall[:processed]}"
    puts "Conversations backfilled:  #{@overall[:backfilled]}"
    puts "Episodes created:          #{@overall[:episodes]}"
    puts "Conversations skipped:     #{@overall[:skipped].values.sum}"
    puts "Failures:                  #{@overall[:failures].size}"
  end

  def candidate_scope(assistant, cutoff)
    Captain::ConversationOutcomeBackfillService.candidate_scope(assistant, cutoff: cutoff)
  end

  def empty_summary
    {
      assistants_processed: 0,
      candidates: 0,
      processed: 0,
      backfilled: 0,
      episodes: 0,
      skipped: Hash.new(0),
      failures: [],
      elapsed: 0.0
    }
  end

  def merge_overall(summary)
    @overall[:assistants_processed] += summary[:assistants_processed]
    @overall[:candidates] += summary[:candidates]
    @overall[:processed] += summary[:processed]
    @overall[:backfilled] += summary[:backfilled]
    @overall[:episodes] += summary[:episodes]
    summary[:skipped].each { |reason, count| @overall[:skipped][reason] += count }
    @overall[:failures].concat(summary[:failures])
  end

  def print_no_assistants(account)
    puts color("Account #{account.name} (ID: #{account.id}) has no Captain assistants.", :yellow)
    puts 'Nothing to backfill.'
  end

  def truncate(value, length)
    value.length > length ? "#{value.first(length - 1)}…" : value
  end

  def color(text, *styles)
    return text unless $stdout.tty?

    codes = styles.filter_map { |style| ANSI_COLORS[style] }.join
    "#{codes}#{text}#{ANSI_COLORS[:reset]}"
  end
end

class Sla::BackfillAppliedSlaCompletedAtService
  DEFAULT_BATCH_SIZE = 500

  def initialize(**options)
    options.assert_valid_keys(:account_id, :all_accounts, :apply, :batch_size, :after_id, :output)

    @account_id = options[:account_id]
    @all_accounts = options.fetch(:all_accounts, false)
    @apply = options.fetch(:apply, false)
    @batch_size = options.fetch(:batch_size, DEFAULT_BATCH_SIZE)
    @after_id = options.fetch(:after_id, 0)
    @output = options.fetch(:output, $stdout)
  end

  def perform
    validate_options!

    scope = candidate_scope
    eligible_count = scope.count
    counters = { processed: 0, matched: 0, updated: 0, skipped: 0, last_id: @after_id }

    print_preflight(eligible_count)

    scope.find_in_batches(batch_size: @batch_size, start: @after_id + 1) { |batch| process_batch(batch, counters) }

    result = counters.merge(eligible: eligible_count, dry_run: !@apply)
    @output.puts "Completed: #{result.inspect}"
    result
  end

  private

  def process_batch(batch, counters)
    resolution_times = resolution_times_for(batch)
    updated_count = @apply ? bulk_update(resolution_times) : 0

    counters[:processed] += batch.size
    counters[:matched] += resolution_times.size
    counters[:updated] += updated_count
    counters[:skipped] += batch.size - resolution_times.size
    counters[:last_id] = batch.last.id

    @output.puts "Processed through applied_sla_id=#{counters[:last_id]} " \
                 "(matched=#{counters[:matched]}, updated=#{counters[:updated]}, skipped=#{counters[:skipped]})"
  end

  def validate_options!
    account_scope = @account_id.present?
    raise ArgumentError, 'Provide exactly one of ACCOUNT_ID or ALL_ACCOUNTS=true' if account_scope == @all_accounts
    raise ArgumentError, 'BATCH_SIZE must be greater than zero' unless @batch_size.positive?
    raise ArgumentError, 'AFTER_ID must be zero or greater' if @after_id.negative?

    Account.find(@account_id) if account_scope
  end

  def candidate_scope
    scope = AppliedSla.where(sla_status: :missed, completed_at: nil).where('applied_slas.id > ?', @after_id)
    scope = scope.where(account_id: @account_id) if @account_id.present?
    scope
  end

  def resolution_times_for(batch)
    events_by_conversation = ReportingEvent
                             .where(
                               account_id: batch.map(&:account_id).uniq,
                               conversation_id: batch.map(&:conversation_id),
                               name: 'conversation_resolved'
                             )
                             .where.not(event_end_time: nil)
                             .order(:conversation_id, event_end_time: :desc)
                             .group_by(&:conversation_id)

    batch.each_with_object({}) do |applied_sla, resolution_times|
      event = events_by_conversation.fetch(applied_sla.conversation_id, []).find do |reporting_event|
        reporting_event.event_end_time.between?(applied_sla.created_at, applied_sla.updated_at)
      end
      resolution_times[applied_sla.id] = event.event_end_time if event
    end
  end

  def bulk_update(resolution_times)
    return 0 if resolution_times.empty?

    connection = AppliedSla.connection
    values = resolution_times.map do |id, completed_at|
      "(#{connection.quote(id)}, #{connection.quote(completed_at)}::timestamp)"
    end.join(', ')

    statement = <<~SQL.squish
      UPDATE #{connection.quote_table_name(AppliedSla.table_name)} AS applied_slas
      SET completed_at = backfill.completed_at
      FROM (VALUES #{values}) AS backfill(id, completed_at)
      WHERE applied_slas.id = backfill.id
        AND applied_slas.completed_at IS NULL
    SQL

    connection.exec_update(statement, 'Backfill applied SLA completed_at')
  end

  def print_preflight(eligible_count)
    scope = @account_id.present? ? "account_id=#{@account_id}" : 'all accounts'
    mode = @apply ? 'APPLY' : 'DRY RUN'
    @output.puts "Applied SLA completed_at backfill: mode=#{mode}, scope=#{scope}, batch_size=#{@batch_size}, after_id=#{@after_id}"
    @output.puts "Eligible missed applied SLAs: #{eligible_count}"
  end
end

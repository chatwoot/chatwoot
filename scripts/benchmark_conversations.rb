# Usage: load 'scripts/benchmark_conversations.rb'; benchmark_conversations(91698, 89557)
# With options: benchmark_conversations(91698, 89557, assignee_type: 'all', status: 'open', team_id: 123)

def benchmark_conversations(account_id, user_id, assignee_type: 'me', status: 'open', team_id: nil)
  account = Account.find(account_id)
  user = User.find(user_id)
  Current.account = account
  Current.user = user
  params = { status: status, assignee_type: assignee_type, page: 1, sort_by: 'last_activity_at_desc' }
  params[:team_id] = team_id if team_id

  queries = []
  subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, start, finish, _id, payload|
    binds = payload[:type_casted_binds] || payload[:binds]&.map(&:value_for_database) || []
    bt = caller.select { |l| l.include?('chatwoot') }.first(5)
    queries << { sql: payload[:sql], duration: (finish - start) * 1000, binds: binds, backtrace: bt }
  end

  # Disable ActiveRecord query cache
  ActiveRecord::Base.uncached do
    start = Time.now
    finder = ConversationFinder.new(user, params)
    result = finder.perform
    conversations = result[:conversations]
    @finder_time = Time.now - start
    @conversations = conversations

    start = Time.now
    conversations.each do |conversation|
      ApplicationController.renderer.render(
        partial: 'api/v1/conversations/partials/conversation',
        locals: { conversation: conversation },
        formats: [:json]
      )
    end
    @render_time = Time.now - start
  end

  ActiveSupport::Notifications.unsubscribe(subscription)
  finder_time = @finder_time
  render_time = @render_time
  conversations = @conversations

  puts "\n=== Timing ==="
  puts "Finder: #{(finder_time * 1000).round(1)}ms"
  puts "Render: #{(render_time * 1000).round(1)}ms"
  puts "Total:  #{((finder_time + render_time) * 1000).round(1)}ms"
  puts "Queries: #{queries.size}"

  puts "\n=== Top 10 Slowest Queries ==="
  queries.select { |q| q[:duration] }.sort_by { |q| -q[:duration] }.first(10).each_with_index do |q, i|
    puts "\n#{i + 1}. #{q[:duration].round(2)}ms"
    puts "   #{q[:sql][0..200]}"
    puts "   Binds: #{q[:binds].inspect[0..200]}" if q[:binds]&.any?
    puts "   Source: #{q[:backtrace]&.first}" if q[:backtrace]&.any?
  end

  # Group queries by conversation_id
  conv_ids = conversations.map(&:id)
  conv_queries = Hash.new { |h, k| h[k] = [] }

  queries.each do |q|
    next unless q[:binds]&.any?

    conv_id = q[:binds].find { |b| conv_ids.include?(b) }
    conv_queries[conv_id] << q if conv_id
  end

  puts "\n=== Queries Per Conversation ==="
  conv_queries.sort_by { |_, qs| -qs.sum { |q| q[:duration] } }.first(5).each do |conv_id, qs|
    total_ms = qs.sum { |q| q[:duration] }.round(2)
    puts "\nConversation #{conv_id}: #{qs.size} queries, #{total_ms}ms total"
    qs.group_by { |q| q[:sql][0..80] }.each do |sql, grouped|
      puts "  #{grouped.size}x #{grouped.sum { |q| q[:duration] }.round(2)}ms - #{sql[0..60]}..."
    end
  end

  puts "\n=== Summary ==="
  puts "Conversations: #{conversations.size}"
  puts "Avg queries/conversation: #{(conv_queries.values.sum(&:size).to_f / conversations.size).round(1)}"

  tied_queries = conv_queries.values.flatten
  untied = queries - tied_queries
  puts "Queries not tied to conversation: #{untied.size}"

  puts "\n=== Untied Queries (grouped by pattern) ==="
  untied.group_by { |q| q[:sql][0..100] }.sort_by { |_, qs| -qs.size }.first(15).each do |sql, qs|
    puts "  #{qs.size}x #{qs.sum { |q| q[:duration] }.round(2)}ms - #{sql[0..80]}..."
  end

  nil
end

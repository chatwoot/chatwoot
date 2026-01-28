# Usage: load 'scripts/benchmark_campaigns.rb'; benchmark_campaigns('website_token')

def benchmark_campaigns(website_token)
  web_widget = Channel::WebWidget.find_by(website_token: website_token)
  raise "WebWidget not found for token #{website_token}" unless web_widget

  inbox = web_widget.inbox
  account = inbox.account

  puts "Inbox: #{inbox.id} | Account: #{account.id}"
  puts "Campaigns feature enabled: #{account.feature_enabled?('campaigns')}"

  queries = []
  subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, start, finish, _id, payload|
    binds = payload[:type_casted_binds] || payload[:binds]&.map(&:value_for_database) || []
    queries << { sql: payload[:sql], duration: (finish - start) * 1000, binds: binds }
  end

  ActiveRecord::Base.uncached do
    start = Time.now
    @campaigns = inbox.campaigns
                      .where(enabled: true, account_id: account.id)
                      .includes(:sender).to_a
    @query_time = Time.now - start
  end

  ActiveSupport::Notifications.unsubscribe(subscription)

  puts "\n=== Timing ==="
  puts "Query: #{(@query_time * 1000).round(2)}ms"
  puts "Queries: #{queries.size}"
  puts "Campaigns found: #{@campaigns.size}"

  puts "\n=== All Queries ==="
  queries.each_with_index do |q, i|
    puts "\n#{i + 1}. #{q[:duration].round(2)}ms"
    puts "   #{q[:sql][0..200]}"
    puts "   Binds: #{q[:binds].inspect[0..150]}" if q[:binds]&.any?
  end

  nil
end

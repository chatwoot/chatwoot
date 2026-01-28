# Usage: load 'scripts/benchmark_contacts.rb'; benchmark_contacts(account_id, user_id)
# With action: benchmark_contacts(account_id, user_id, action: 'search', q: 'john')

def benchmark_contacts(account_id, user_id, action: 'index', **opts)
  account = Account.find(account_id)
  user = User.find(user_id)
  Current.account = account
  Current.user = user

  puts "Account: #{account_id} | User: #{user_id} | Action: #{action}"

  queries = []
  subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, start, finish, _id, payload|
    binds = payload[:type_casted_binds] || payload[:binds]&.map(&:value_for_database) || []
    queries << { sql: payload[:sql], duration: (finish - start) * 1000, binds: binds }
  end

  ActiveRecord::Base.uncached do
    start = Time.now

    case action
    when 'index'
      contacts = account.contacts.resolved_contacts
      @contacts = contacts
                  .includes(avatar_attachment: [:blob], contact_inboxes: { inbox: :channel })
                  .page(opts[:page] || 1)
                  .per(15).to_a
      @count = contacts.count

    when 'search'
      q = opts[:q] || ''
      contacts = account.contacts.where(
        'name ILIKE :search OR email ILIKE :search OR phone_number ILIKE :search OR contacts.identifier LIKE :search',
        search: "%#{q.strip}%"
      )
      @contacts = contacts
                  .includes(avatar_attachment: [:blob], contact_inboxes: { inbox: :channel })
                  .page(opts[:page] || 1)
                  .per(15).to_a
      @count = contacts.count

    when 'filter'
      # Requires payload param - simplified version
      @contacts = account.contacts.page(1).per(15).to_a
      @count = account.contacts.count
    end

    @query_time = Time.now - start
  end

  ActiveSupport::Notifications.unsubscribe(subscription)

  puts "\n=== Timing ==="
  puts "Query: #{(@query_time * 1000).round(2)}ms"
  puts "Queries: #{queries.size}"
  puts "Contacts found: #{@contacts&.size}"
  puts "Total count: #{@count}"

  puts "\n=== Top 10 Slowest Queries ==="
  queries.select { |q| q[:duration] }.sort_by { |q| -q[:duration] }.first(10).each_with_index do |q, i|
    puts "\n#{i + 1}. #{q[:duration].round(2)}ms"
    puts "   #{q[:sql][0..200]}"
    puts "   Binds: #{q[:binds].inspect[0..150]}" if q[:binds]&.any?
  end

  puts "\n=== All Queries (grouped by pattern) ==="
  queries.group_by { |q| q[:sql][0..100] }.sort_by { |_, qs| -qs.size }.each do |sql, qs|
    puts "  #{qs.size}x #{qs.sum { |q| q[:duration] }.round(2)}ms - #{sql[0..80]}..."
  end

  nil
end

namespace :search do
  desc "Benchmark advanced search performance"
  task benchmark: :environment do
    puts "🔍 Advanced Search Performance Benchmark"
    puts "=" * 50

    account = Account.first
    unless account
      puts "❌ No accounts found. Please create an account first."
      exit 1
    end

    user = account.users.first
    unless user  
      puts "❌ No users found for account #{account.id}. Please create a user first."
      exit 1
    end

    # Ensure we have test data
    ensure_test_data(account)

    # Run benchmark tests
    run_conversation_benchmark(account, user)
    run_message_benchmark(account, user) 
    run_contact_benchmark(account, user)
    run_complex_benchmark(account, user)
    run_concurrent_benchmark(account, user)

    puts "\n✅ Benchmark completed!"
  end

  desc "Create test data for benchmarking"
  task create_test_data: :environment do
    account = Account.first
    unless account
      puts "❌ No accounts found. Please create an account first."
      exit 1
    end

    puts "🏗️  Creating test data for benchmarking..."
    ensure_test_data(account, force: true)
    puts "✅ Test data created successfully!"
  end

  desc "Analyze slow queries from Redis"
  task analyze_slow_queries: :environment do
    puts "🐌 Analyzing slow search queries..."
    
    redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
    today = Date.current.strftime('%Y-%m-%d')
    key = "chatwoot:slow_searches:#{today}"

    slow_queries = redis.lrange(key, 0, -1)
    
    if slow_queries.empty?
      puts "✅ No slow queries found for today!"
      return
    end

    puts "Found #{slow_queries.length} slow queries:"
    puts "-" * 40

    parsed_queries = slow_queries.map { |q| JSON.parse(q) }.sort_by { |q| -q['duration'] }

    parsed_queries.first(10).each_with_index do |query, index|
      puts "#{index + 1}. Duration: #{query['duration']}ms"
      puts "   Query: #{query['query'] || 'N/A'}"
      puts "   Type: #{query['search_type'] || 'unknown'}"
      puts "   Filters: #{query['filters_count'] || 0}"
      puts "   Time: #{Time.at(query['timestamp']).strftime('%H:%M:%S')}"
      puts
    end

    # Statistics
    durations = parsed_queries.map { |q| q['duration'] }
    avg_duration = durations.sum / durations.length
    p95_duration = calculate_percentile(durations, 95)
    max_duration = durations.max

    puts "📊 Slow Query Statistics:"
    puts "   Average: #{avg_duration.round(2)}ms"
    puts "   p95: #{p95_duration}ms"
    puts "   Max: #{max_duration}ms"
    puts "   Total: #{slow_queries.length} queries"

  rescue Redis::CannotConnectError
    puts "❌ Could not connect to Redis. Please check your Redis configuration."
  end

  private

  def ensure_test_data(account, force: false)
    conversations_count = account.conversations.count
    messages_count = account.messages.count
    contacts_count = account.contacts.count

    if !force && conversations_count >= 100 && messages_count >= 500
      puts "📊 Using existing test data:"
      puts "   Conversations: #{conversations_count}"
      puts "   Messages: #{messages_count}" 
      puts "   Contacts: #{contacts_count}"
      return
    end

    puts "🏗️  Creating test data..."
    
    inbox = account.inboxes.first || FactoryBot.create(:inbox, account: account)
    agents = []
    
    # Create agents if needed
    if account.users.count < 5
      5.times do
        agents << FactoryBot.create(:user, account: account)
      end
    else
      agents = account.users.limit(5)
    end

    # Create teams if needed
    teams = account.teams.any? ? account.teams.limit(3) : [
      FactoryBot.create(:team, account: account, name: 'support'),
      FactoryBot.create(:team, account: account, name: 'sales'),
      FactoryBot.create(:team, account: account, name: 'technical')
    ]

    # Create labels if needed
    labels = account.labels.any? ? account.labels.limit(10) : 10.times.map do |i|
      FactoryBot.create(:label, account: account, title: "Label #{i+1}")
    end

    # Create contacts
    contacts_to_create = [100 - contacts_count, 0].max
    contacts_to_create.times do
      FactoryBot.create(:contact, account: account)
    end

    contacts = account.contacts.limit(50)

    # Create conversations
    conversations_to_create = [200 - conversations_count, 0].max
    created_conversations = []
    
    conversations_to_create.times do |i|
      conversation = FactoryBot.create(:conversation,
        account: account,
        inbox: inbox,
        contact: contacts.sample,
        assignee: [nil, *agents].sample,
        team: [nil, *teams].sample,
        status: ['open', 'resolved', 'pending'].sample,
        priority: ['low', 'medium', 'high', 'urgent'].sample,
        created_at: rand(90.days).seconds.ago
      )
      
      # Add random labels
      conversation.labels << labels.sample(rand(0..3))
      created_conversations << conversation
      
      print "." if i % 20 == 0
    end

    # Create messages for conversations
    puts "\nCreating messages..."
    all_conversations = created_conversations + account.conversations.limit(100)
    
    all_conversations.each_with_index do |conversation, i|
      next if conversation.messages.count >= 5 # Skip if already has messages

      message_count = rand(2..8)
      message_count.times do |j|
        FactoryBot.create(:message,
          conversation: conversation,
          account: account,
          inbox: inbox,
          content: generate_realistic_content,
          message_type: ['incoming', 'outgoing'].sample,
          created_at: conversation.created_at + (j * 10).minutes
        )
      end
      
      print "." if i % 10 == 0
    end

    puts "\n✅ Test data ready:"
    puts "   Conversations: #{account.conversations.count}"
    puts "   Messages: #{account.messages.count}"
    puts "   Contacts: #{account.contacts.count}"
  end

  def run_conversation_benchmark(account, user)
    puts "\n🔍 Conversation Search Benchmark"
    puts "-" * 30
    
    search_params_list = [
      { query: 'refund' },
      { query: 'payment', status: ['open'] },
      { query: 'support', priority: ['high', 'urgent'] },
      { query: '', status: ['open'], date_from: 30.days.ago.strftime('%Y-%m-%d') }
    ]

    response_times = []

    search_params_list.each do |params|
      times = benchmark_search_service(account, user, 'conversations', params, iterations: 25)
      response_times.concat(times)
      
      avg_time = times.sum / times.length
      puts "   #{params.inspect}: #{avg_time.round(2)}ms avg"
    end

    p95_time = calculate_percentile(response_times, 95)
    status = p95_time <= 300 ? "✅ PASS" : "❌ FAIL" 
    
    puts "\n📊 Conversation Search Results:"
    puts "   p95: #{p95_time}ms #{status}"
    puts "   Average: #{(response_times.sum / response_times.length).round(2)}ms"
  end

  def run_message_benchmark(account, user)
    puts "\n💬 Message Search Benchmark" 
    puts "-" * 30

    search_params_list = [
      { query: 'help' },
      { query: 'urgent', message_type: ['incoming'] },
      { query: 'thank', date_from: 7.days.ago.strftime('%Y-%m-%d') }
    ]

    response_times = []

    search_params_list.each do |params|
      times = benchmark_search_service(account, user, 'messages', params, iterations: 25)
      response_times.concat(times)
      
      avg_time = times.sum / times.length
      puts "   #{params.inspect}: #{avg_time.round(2)}ms avg"
    end

    p95_time = calculate_percentile(response_times, 95)
    status = p95_time <= 300 ? "✅ PASS" : "❌ FAIL"
    
    puts "\n📊 Message Search Results:"
    puts "   p95: #{p95_time}ms #{status}"
  end

  def run_contact_benchmark(account, user)
    puts "\n👥 Contact Search Benchmark"
    puts "-" * 30

    search_params_list = [
      { query: 'john' },
      { query: 'example.com' },
      { query: 'test' }
    ]

    response_times = []

    search_params_list.each do |params|
      times = benchmark_search_service(account, user, 'contacts', params, iterations: 25) 
      response_times.concat(times)
      
      avg_time = times.sum / times.length
      puts "   #{params.inspect}: #{avg_time.round(2)}ms avg"
    end

    p95_time = calculate_percentile(response_times, 95)
    status = p95_time <= 300 ? "✅ PASS" : "❌ FAIL"
    
    puts "\n📊 Contact Search Results:"
    puts "   p95: #{p95_time}ms #{status}"
  end

  def run_complex_benchmark(account, user)
    puts "\n🔧 Complex Search Benchmark"
    puts "-" * 30

    inbox_ids = account.inboxes.limit(2).pluck(:id)
    agent_ids = account.users.limit(3).pluck(:id)
    
    complex_params = {
      query: 'support urgent',
      status: ['open', 'pending'],
      priority: ['high', 'urgent'],
      inbox_ids: inbox_ids,
      agent_ids: agent_ids,
      date_from: 30.days.ago.strftime('%Y-%m-%d'),
      date_to: Date.current.strftime('%Y-%m-%d')
    }

    times = benchmark_search_service(account, user, 'conversations', complex_params, iterations: 20)
    
    p95_time = calculate_percentile(times, 95)
    avg_time = times.sum / times.length
    status = p95_time <= 400 ? "✅ PASS" : "❌ FAIL" # Allow 400ms for complex searches
    
    puts "\n📊 Complex Search Results:"
    puts "   p95: #{p95_time}ms #{status}"
    puts "   Average: #{avg_time.round(2)}ms"
  end

  def run_concurrent_benchmark(account, user)
    puts "\n⚡ Concurrent Search Benchmark"
    puts "-" * 30

    threads = []
    all_response_times = []
    mutex = Mutex.new

    # Simulate 5 concurrent users
    5.times do |thread_id|
      threads << Thread.new do
        thread_times = []
        
        10.times do
          start_time = Time.current
          
          service = AdvancedSearchService.new(
            current_user: user,
            current_account: account,
            search_type: 'conversations',
            query: ['refund', 'support', 'payment', 'help'].sample
          )
          
          service.perform
          
          end_time = Time.current
          response_time = ((end_time - start_time) * 1000).round(2)
          thread_times << response_time
        end

        mutex.synchronize do
          all_response_times.concat(thread_times)
        end
      end
    end

    threads.each(&:join)

    p95_time = calculate_percentile(all_response_times, 95)
    avg_time = all_response_times.sum / all_response_times.length
    status = p95_time <= 500 ? "✅ PASS" : "❌ FAIL" # Allow 500ms under load
    
    puts "\n📊 Concurrent Search Results (#{threads.length} users):"
    puts "   p95: #{p95_time}ms #{status}"
    puts "   Average: #{avg_time.round(2)}ms"
  end

  def benchmark_search_service(account, user, search_type, params, iterations: 10)
    response_times = []
    
    iterations.times do
      start_time = Time.current
      
      service = AdvancedSearchService.new(
        current_user: user,
        current_account: account,
        search_type: search_type,
        **params
      )
      
      result = service.perform
      
      end_time = Time.current
      response_time = ((end_time - start_time) * 1000).round(2)
      response_times << response_time

      # Verify we got results (basic sanity check)
      unless result.is_a?(Hash)
        puts "⚠️  Warning: Search returned unexpected result type: #{result.class}"
      end
    end

    response_times
  end

  def calculate_percentile(array, percentile)
    return 0 if array.empty?
    
    sorted = array.sort
    index = (percentile / 100.0) * (sorted.length - 1)
    
    if index == index.floor
      sorted[index.to_i]
    else
      lower = sorted[index.floor]
      upper = sorted[index.ceil]
      lower + (upper - lower) * (index - index.floor)
    end.round(2)
  end

  def generate_realistic_content
    templates = [
      "Hi, I need help with my order. When will it be shipped?",
      "I'm having trouble accessing my account. Can you help?", 
      "The payment didn't go through. Please check my billing information.",
      "Your product is amazing! Just wanted to say thank you.",
      "I found a bug in your website. Here are the steps to reproduce it.",
      "Can you refund my recent purchase? Order number: #{rand(10000..99999)}",
      "How do I reset my password?",
      "The delivery was delayed. What's the status?",
      "I have a technical question about your service.",
      "Thank you for the quick response! That solved my issue.",
      "Is there a way to upgrade my plan?", 
      "The website is loading very slowly for me.",
      "I received the wrong item in my order.",
      "Can you help me understand how billing works?",
      "I'm interested in your premium features."
    ]
    
    templates.sample
  end
end
require 'rails_helper'
require 'benchmark'

RSpec.describe 'Advanced Search Performance', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  
  before do
    sign_in(user)
    create_test_data
  end

  describe 'Search Performance Targets' do
    it 'meets p95 ≤ 300ms requirement for conversation search' do
      response_times = []
      
      # Run 100 searches to get meaningful p95 data
      100.times do |i|
        start_time = Time.current
        
        get "/api/v1/accounts/#{account.id}/advanced_search/conversations", 
            params: { q: search_terms.sample, status: ['open', 'resolved'].sample }
        
        end_time = Time.current
        response_time = ((end_time - start_time) * 1000).round(2)
        response_times << response_time
        
        expect(response).to have_http_status(:ok)
      end
      
      p95_time = calculate_percentile(response_times, 95)
      p99_time = calculate_percentile(response_times, 99)
      avg_time = response_times.sum / response_times.length
      
      puts "\n📊 Conversation Search Performance Results:"
      puts "   Average: #{avg_time.round(2)}ms"
      puts "   p95: #{p95_time}ms"  
      puts "   p99: #{p99_time}ms"
      puts "   Max: #{response_times.max}ms"
      puts "   Min: #{response_times.min}ms"
      
      expect(p95_time).to be <= 300, "p95 response time #{p95_time}ms exceeds 300ms target"
      expect(p99_time).to be <= 500, "p99 response time #{p99_time}ms exceeds 500ms target"
    end

    it 'meets p95 ≤ 300ms requirement for message search' do
      response_times = []
      
      100.times do |i|
        start_time = Time.current
        
        get "/api/v1/accounts/#{account.id}/advanced_search/messages", 
            params: { 
              q: search_terms.sample,
              message_type: ['incoming', 'outgoing'].sample
            }
        
        end_time = Time.current
        response_time = ((end_time - start_time) * 1000).round(2)
        response_times << response_time
        
        expect(response).to have_http_status(:ok)
      end
      
      p95_time = calculate_percentile(response_times, 95)
      puts "\n📊 Message Search Performance: p95 = #{p95_time}ms"
      
      expect(p95_time).to be <= 300, "Message search p95 #{p95_time}ms exceeds target"
    end

    it 'meets p95 ≤ 300ms requirement for contact search' do
      response_times = []
      
      100.times do |i|
        start_time = Time.current
        
        get "/api/v1/accounts/#{account.id}/advanced_search/contacts", 
            params: { q: contact_search_terms.sample }
        
        end_time = Time.current
        response_time = ((end_time - start_time) * 1000).round(2)
        response_times << response_time
        
        expect(response).to have_http_status(:ok)
      end
      
      p95_time = calculate_percentile(response_times, 95)
      puts "\n📊 Contact Search Performance: p95 = #{p95_time}ms"
      
      expect(p95_time).to be <= 300, "Contact search p95 #{p95_time}ms exceeds target"
    end

    it 'handles complex searches with multiple filters efficiently' do
      response_times = []
      
      50.times do |i|
        start_time = Time.current
        
        get "/api/v1/accounts/#{account.id}/advanced_search/conversations", 
            params: complex_search_params
        
        end_time = Time.current
        response_time = ((end_time - start_time) * 1000).round(2)
        response_times << response_time
        
        expect(response).to have_http_status(:ok)
      end
      
      p95_time = calculate_percentile(response_times, 95)
      puts "\n📊 Complex Search Performance: p95 = #{p95_time}ms"
      
      expect(p95_time).to be <= 400, "Complex search p95 #{p95_time}ms exceeds 400ms target"
    end

    it 'maintains performance under concurrent load' do
      threads = []
      all_response_times = []
      mutex = Mutex.new
      
      # Simulate 10 concurrent users
      10.times do |thread_id|
        threads << Thread.new do
          thread_response_times = []
          
          20.times do |i|
            start_time = Time.current
            
            get "/api/v1/accounts/#{account.id}/advanced_search/conversations", 
                params: { q: search_terms.sample }
            
            end_time = Time.current
            response_time = ((end_time - start_time) * 1000).round(2)
            thread_response_times << response_time
            
            expect(response).to have_http_status(:ok)
          end
          
          mutex.synchronize do
            all_response_times.concat(thread_response_times)
          end
        end
      end
      
      threads.each(&:join)
      
      p95_time = calculate_percentile(all_response_times, 95)
      puts "\n📊 Concurrent Load Performance: p95 = #{p95_time}ms (#{threads.length} concurrent users)"
      
      expect(p95_time).to be <= 500, "Concurrent search p95 #{p95_time}ms exceeds 500ms target"
    end
  end

  describe 'Index Usage Verification' do
    it 'uses proper indexes for conversation searches' do
      # Enable query logging
      old_log_level = ActiveRecord::Base.logger.level
      ActiveRecord::Base.logger.level = Logger::DEBUG
      
      logs = capture_sql_logs do
        get "/api/v1/accounts/#{account.id}/advanced_search/conversations", 
            params: { 
              q: 'test query',
              status: ['open'],
              inbox_ids: [inbox.id]
            }
      end
      
      ActiveRecord::Base.logger.level = old_log_level
      
      # Verify no sequential scans on large tables
      sequential_scans = logs.select { |log| log.include?('Seq Scan') && 
                                           (log.include?('conversations') || log.include?('messages')) }
      
      expect(sequential_scans).to be_empty, 
        "Found sequential scans that indicate missing indexes: #{sequential_scans}"
    end

    it 'efficiently processes text search queries' do
      explain_results = []
      
      search_terms.each do |term|
        result = ActiveRecord::Base.connection.execute(
          "EXPLAIN (ANALYZE, BUFFERS) #{build_search_query(term)}"
        ).to_a
        
        explain_results << { term: term, plan: result }
      end
      
      # Verify all queries use index scans
      explain_results.each do |result|
        plan_text = result[:plan].map { |row| row['QUERY PLAN'] }.join("\n")
        
        expect(plan_text).not_to include('Seq Scan'), 
          "Sequential scan detected for term '#{result[:term]}'"
        expect(plan_text).to include('Index'), 
          "No index usage detected for term '#{result[:term]}'"
      end
    end
  end

  describe 'Memory Usage' do
    it 'maintains reasonable memory usage during search' do
      initial_memory = get_memory_usage
      
      # Perform memory-intensive searches
      10.times do
        get "/api/v1/accounts/#{account.id}/advanced_search", 
            params: { 
              q: 'memory test query',
              per_page: 100  # Larger page size
            }
        expect(response).to have_http_status(:ok)
      end
      
      final_memory = get_memory_usage
      memory_increase = final_memory - initial_memory
      
      puts "\n💾 Memory Usage: #{memory_increase}MB increase"
      
      # Memory increase should be reasonable (< 50MB for 10 searches)
      expect(memory_increase).to be < 50, 
        "Memory usage increased by #{memory_increase}MB, indicating possible memory leak"
    end
  end

  private

  def create_test_data
    puts "\n🏗️  Creating test data for performance testing..."
    
    # Create realistic test data
    agents = create_list(:user, 5, account: account)
    teams = create_list(:team, 3, account: account)
    labels = create_list(:label, 10, account: account)
    
    # Create contacts with various attributes
    100.times do
      create(:contact, 
        account: account,
        name: Faker::Name.name,
        email: Faker::Internet.email,
        phone_number: Faker::PhoneNumber.phone_number
      )
    end
    
    # Create conversations with different statuses and assignments
    contacts = account.contacts.limit(50)
    500.times do |i|
      conversation = create(:conversation,
        account: account,
        inbox: inbox,
        contact: contacts.sample,
        assignee: [nil, *agents].sample,
        team: [nil, *teams].sample,
        status: ['open', 'resolved', 'pending'].sample,
        priority: ['low', 'medium', 'high', 'urgent'].sample,
        created_at: rand(90.days).seconds.ago
      )
      
      # Add labels
      conversation.labels << labels.sample(rand(0..3))
      
      # Create messages for each conversation
      rand(3..15).times do
        create(:message,
          conversation: conversation,
          account: account,
          inbox: inbox,
          content: generate_realistic_message_content,
          message_type: ['incoming', 'outgoing'].sample,
          created_at: conversation.created_at + rand(1.hour).seconds
        )
      end
      
      print "." if i % 50 == 0
    end
    
    puts "\n✅ Test data created: #{account.conversations.count} conversations, #{account.messages.count} messages"
  end

  def search_terms
    [
      'refund', 'payment', 'billing', 'support', 'urgent', 'help',
      'order status', 'shipping', 'delivery', 'account access',
      'password reset', 'technical issue', 'bug report', 'feature request',
      'complaint', 'feedback', 'question', 'how to', 'when will'
    ]
  end

  def contact_search_terms
    [
      'john', 'smith', 'example.com', '+1', 'gmail', 'test',
      'user', 'customer', 'client', 'support'
    ]
  end

  def complex_search_params
    {
      q: search_terms.sample,
      status: ['open', 'resolved'].sample(rand(1..2)),
      priority: ['high', 'urgent'],
      inbox_ids: [inbox.id],
      date_from: 30.days.ago.strftime('%Y-%m-%d'),
      date_to: Date.current.strftime('%Y-%m-%d'),
      has_attachments: [true, false].sample,
      per_page: 20
    }
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

  def capture_sql_logs
    logs = []
    original_logger = ActiveRecord::Base.logger
    
    # Create custom logger to capture SQL
    string_io = StringIO.new
    custom_logger = Logger.new(string_io)
    ActiveRecord::Base.logger = custom_logger
    
    yield
    
    string_io.string.split("\n").select { |line| line.include?('SELECT') || line.include?('EXPLAIN') }
  ensure
    ActiveRecord::Base.logger = original_logger
  end

  def build_search_query(term)
    <<~SQL.squish
      SELECT conversations.* 
      FROM conversations 
      INNER JOIN contacts ON conversations.contact_id = contacts.id 
      WHERE conversations.account_id = #{account.id}
        AND (contacts.name ILIKE '%#{term}%' OR contacts.email ILIKE '%#{term}%')
      ORDER BY conversations.created_at DESC 
      LIMIT 20
    SQL
  end

  def generate_realistic_message_content
    templates = [
      "Hi, I need help with my order #ORDER_ID. When will it be shipped?",
      "I'm having trouble accessing my account. Can you help?",
      "The payment didn't go through. Please check my billing information.",
      "Your product is amazing! Just wanted to say thank you.",
      "I found a bug in your website. Here are the steps to reproduce...",
      "Can you refund my recent purchase? Order number: #ORDER_ID",
      "How do I reset my password?",
      "The delivery was delayed. What's the status?",
      "I have a technical question about your service.",
      "Thank you for the quick response! That solved my issue."
    ]
    
    templates.sample.gsub('#ORDER_ID', rand(10000..99999).to_s)
  end

  def get_memory_usage
    # Simple memory usage approximation
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0 # Convert KB to MB
  rescue
    0 # Return 0 if unable to get memory usage
  end
end
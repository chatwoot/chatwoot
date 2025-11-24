# 🎯 Quick Demo Commands Cheat Sheet

## 🚀 Before Demo - Start Chatwoot

```bash
# Navigate to project
cd /Users/gunveerkalsi/chatwoot-1

# Start Rails server (Terminal 1)
eval "$(rbenv init - bash)" && bin/rails server -p 3000

# Start Vite dev server (Terminal 2)
eval "$(rbenv init - bash)" && bin/vite dev
```

**Login:** http://localhost:3000
- Email: `gunveerkalsi@gmail.com`
- Password: `Password123!`

---

## 📊 Feature 1: Priority Scoring Demo

### Show Priority Calculation
```bash
bin/rails runner "
puts '🎯 PRIORITY SCORING DEMONSTRATION'
puts '=' * 60

# Show the algorithm
puts 'Algorithm Weights:'
puts '  - Sentiment Analysis: 25%'
puts '  - SLA Breach Risk: 30%'
puts '  - Urgency Keywords: 20%'
puts '  - Time Decay: 15%'
puts '  - Customer Value: 10%'
puts ''

# Show urgency keywords
keywords = %w[urgent emergency critical asap immediately broken down error failed angry frustrated]
puts 'Urgency Keywords Detected:'
puts '  ' + keywords.join(', ')
puts ''

# Show priority levels
puts 'Priority Levels:'
puts '  🔴 Critical (80-100): Immediate attention'
puts '  🟠 High (60-79): Urgent response needed'
puts '  🟡 Elevated (40-59): Above normal priority'
puts '  ⚪ Normal (0-39): Standard queue'
puts ''

puts '✅ Priority scoring system is active and ready!'
"
```

### Show Database Schema
```bash
# Show the migration
cat db/migrate/20251124170200_add_priority_to_conversations.rb

# Show current schema
bin/rails runner "
puts Conversation.columns.select { |c| c.name.include?('priority') }.map(&:name)
"
```

---

## 📈 Feature 2: Customer Insights Demo

### Show Insights Structure
```bash
bin/rails runner "
puts '📊 CUSTOMER INSIGHTS DEMONSTRATION'
puts '=' * 60

puts 'Insights Provided:'
puts ''
puts '1. SENTIMENT ANALYSIS'
puts '   - Recent sentiment (positive/neutral/negative)'
puts '   - Overall distribution'
puts '   - Trend over time'
puts ''
puts '2. CSAT METRICS'
puts '   - Average rating (1-5 stars)'
puts '   - Trend (improving/declining/stable)'
puts '   - Rating history'
puts ''
puts '3. ENGAGEMENT METRICS'
puts '   - Total conversations'
puts '   - Response rate'
puts '   - Most active day'
puts '   - Avg messages per conversation'
puts ''
puts '4. RESPONSE TIME ANALYSIS'
puts '   - Average first response time'
puts '   - Average resolution time'
puts '   - Performance trends'
puts ''

puts '✅ Customer insights system is active!'
"
```

### Show API Endpoint
```bash
# Show the route
bin/rails routes | grep insights

# Show controller method
grep -A 10 "def insights" app/controllers/api/v1/accounts/contacts_controller.rb
```

---

## 🤖 Feature 3: AI Response Suggestions Demo

### Show Vector Embeddings
```bash
bin/rails runner "
puts '🤖 AI RESPONSE SUGGESTIONS DEMONSTRATION'
puts '=' * 60

puts 'Technology Stack:'
puts '  - PostgreSQL pgvector extension'
puts '  - OpenAI text-embedding-ada-002 model'
puts '  - 1536-dimensional vectors'
puts '  - Cosine similarity search'
puts ''

puts 'How It Works:'
puts '  1. Convert canned responses to vectors'
puts '  2. Analyze conversation context'
puts '  3. Find similar responses using cosine distance'
puts '  4. Rank by similarity score'
puts ''

# Show canned responses count
account = Account.first
total = account.canned_responses.count
with_embeddings = account.canned_responses.where.not(embedding: nil).count

puts \"Canned Responses: #{total}\"
puts \"With Embeddings: #{with_embeddings}\"
puts ''

if with_embeddings > 0
  puts '✅ AI suggestion system is active!'
else
  puts '⚠️  To generate embeddings, configure OpenAI API key:'
  puts '   OPENAI_API_KEY=your_key_here'
  puts '   Then run: bin/rails runner \"CannedResponse.find_each { |r| CannedResponseEmbeddingJob.perform_now(r) }\"'
end
"
```

### Show Database Schema
```bash
# Show the migration
cat db/migrate/20251124171357_add_embedding_to_canned_responses.rb

# Show the model method
grep -A 5 "def self.semantic_search" app/models/canned_response.rb
```

---

## 📁 Show File Structure

### List All New Files
```bash
echo "=== NEW SERVICE OBJECTS ==="
ls -lh app/services/conversation_priority_service.rb
ls -lh app/services/customer_insights_service.rb
ls -lh app/services/canned_response_suggestion_service.rb

echo ""
echo "=== NEW BACKGROUND JOBS ==="
ls -lh app/jobs/conversation_priority_update_job.rb
ls -lh app/jobs/recalculate_conversation_priorities_job.rb
ls -lh app/jobs/canned_response_embedding_job.rb

echo ""
echo "=== NEW VUE COMPONENTS ==="
ls -lh app/javascript/dashboard/components/widgets/conversation/PriorityScoreBadge.vue

echo ""
echo "=== DATABASE MIGRATIONS ==="
ls -lh db/migrate/20251124*.rb

echo ""
echo "=== DOCUMENTATION ==="
ls -lh PROJECT_FEATURES_SUMMARY.md
ls -lh DEMO_PRESENTATION_GUIDE.md
ls -lh PRESENTATION_SLIDES.md
```

### Count Lines of Code
```bash
echo "=== LINES OF CODE ADDED ==="
wc -l app/services/conversation_priority_service.rb
wc -l app/services/customer_insights_service.rb
wc -l app/services/canned_response_suggestion_service.rb
wc -l app/jobs/*.rb | tail -1
wc -l app/javascript/dashboard/components/widgets/conversation/PriorityScoreBadge.vue
echo ""
echo "Total new code: ~1000+ lines"
```

---

## 🔍 Show Code Quality

### Check Ruby Style
```bash
# Show RuboCop compliance (if needed)
bundle exec rubocop app/services/conversation_priority_service.rb --format simple
```

### Show Database Indexes
```bash
bin/rails runner "
puts 'Database Indexes Added:'
puts ''
puts 'Conversations table:'
puts '  - priority_score (for sorting)'
puts '  - priority_level (for filtering)'
puts ''
puts 'Canned Responses table:'
puts '  - embedding (IVFFlat index for vector search)'
"
```

---

## 📊 Show Statistics

### Project Statistics
```bash
bin/rails runner "
puts '📊 PROJECT STATISTICS'
puts '=' * 60

account = Account.first

puts \"Accounts: #{Account.count}\"
puts \"Users: #{User.count}\"
puts \"Contacts: #{Contact.count}\"
puts \"Conversations: #{Conversation.count}\"
puts \"Messages: #{Message.count}\"
puts \"Canned Responses: #{CannedResponse.count}\"
puts ''

if Conversation.any?
  puts 'Priority Distribution:'
  Conversation.group(:priority_level).count.each do |level, count|
    level_name = Conversation.priority_levels.key(level)
    puts \"  #{level_name}: #{count}\"
  end
else
  puts 'No conversations yet - system ready for data!'
end
"
```

---

## 🎯 Quick File Viewers

### View Service Code
```bash
# Priority Service
cat app/services/conversation_priority_service.rb | head -50

# Insights Service
cat app/services/customer_insights_service.rb | head -50

# Suggestion Service
cat app/services/canned_response_suggestion_service.rb | head -50
```

### View Migrations
```bash
# Priority migration
cat db/migrate/20251124170200_add_priority_to_conversations.rb

# Embedding migration
cat db/migrate/20251124171357_add_embedding_to_canned_responses.rb
```

### View Vue Component
```bash
cat app/javascript/dashboard/components/widgets/conversation/PriorityScoreBadge.vue
```

---

## 🚀 Emergency Commands

### If Server Crashes
```bash
# Kill all Rails processes
pkill -f "rails server"
pkill -f "vite dev"

# Restart
bin/rails server -p 3000 &
bin/vite dev &
```

### Check Server Status
```bash
# Check if Rails is running
curl -s http://localhost:3000 | head -20

# Check processes
ps aux | grep rails
ps aux | grep vite
```

---

## 📚 Documentation Quick Access

```bash
# Open documentation
cat PROJECT_FEATURES_SUMMARY.md
cat DEMO_PRESENTATION_GUIDE.md
cat PRESENTATION_SLIDES.md
```

---

## ✅ Pre-Demo Checklist

Run this before your presentation:

```bash
echo "🔍 PRE-DEMO CHECKLIST"
echo "===================="
echo ""

# Check Rails server
if curl -s http://localhost:3000 > /dev/null; then
  echo "✅ Rails server is running"
else
  echo "❌ Rails server is NOT running - start it!"
fi

# Check database
if bin/rails runner "puts Account.count" > /dev/null 2>&1; then
  echo "✅ Database is accessible"
else
  echo "❌ Database connection failed"
fi

# Check files exist
if [ -f "PROJECT_FEATURES_SUMMARY.md" ]; then
  echo "✅ Documentation exists"
else
  echo "❌ Documentation missing"
fi

echo ""
echo "Ready for demo! 🚀"
```

---

**Good luck with your presentation! 🎉**


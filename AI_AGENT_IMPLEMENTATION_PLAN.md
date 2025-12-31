# Aloo Agent Implementation Plan (Captain OSS Alternative)

This document outlines the implementation plan for creating an AI agent system in the open-source version of Chatwoot, replicating the functionality of the Enterprise "Captain" feature using **RubyLLM** and **ruby_llm-agents** gems.

## Table of Contents

1. [Overview](#overview)
2. [Gem Stack & Configuration](#gem-stack--configuration)
3. [Model Recommendations](#model-recommendations)
4. [Personality & Language Configuration](#personality--language-configuration)
5. [Architecture](#architecture)
6. [Phase 1: Foundation & Database Setup](#phase-1-foundation--database-setup)
7. [Phase 2: Agent Framework](#phase-2-agent-framework)
8. [Phase 3: Knowledge Base & Embeddings](#phase-3-knowledge-base--embeddings)
9. [Phase 4: Tools System (MCPs)](#phase-4-tools-system-mcps)
10. [Phase 5: Onboarding & Data Ingestion](#phase-5-onboarding--data-ingestion)
11. [Phase 6: Conversation Integration](#phase-6-conversation-integration)
12. [Phase 7: Frontend & Dashboard](#phase-7-frontend--dashboard)
13. [Phase 8: Advanced Features](#phase-8-advanced-features)

---

## Overview

### Goals

- Create an AI agent system that handles customer conversations autonomously
- Support multiple knowledge sources: websites, files (PDF, CSV), and Notion
- Use vector embeddings for semantic search and context retrieval
- Implement a flexible tools system (MCPs) for agent capabilities
- Built-in execution tracking, cost analytics, and monitoring dashboard
- Integrate seamlessly with existing Chatwoot conversation flow

### Tech Stack

| Component | Technology |
|-----------|------------|
| **LLM Integration** | [ruby_llm](https://rubyllm.com) (500+ models) |
| **Agent Framework** | [ruby_llm-agents](https://github.com/adham90/ruby_llm-agents) |
| **Vector Database** | PostgreSQL + pgvector |
| **Vector Search** | neighbor gem (HNSW indexing) |
| **Embeddings** | OpenAI text-embedding-3-small (1536d) |
| **Background Jobs** | Sidekiq (existing) |
| **LLM Serialization** | toon-ruby (token-efficient encoding) |

---

## Gem Stack & Configuration

### Gemfile Dependencies

```ruby
# Aloo Agent Core
gem 'ruby_llm', '~> 1.2'              # Multi-provider LLM abstraction
gem 'ruby_llm-agents'                  # Agent framework with dashboard

# Vector Search
gem 'neighbor', '~> 0.5'               # pgvector Rails integration

# Data Processing
gem 'pdf-reader', '~> 2.12'            # PDF parsing
gem 'notion-ruby-client', '~> 1.3'     # Notion API
gem 'toon-ruby'                        # LLM-friendly encoding

# Optional: Web Scraping
gem 'nokogiri'                         # HTML parsing (already in Chatwoot)
gem 'spidr', '~> 0.7'                  # Web crawler
```

### RubyLLM Configuration

Create `config/initializers/ruby_llm.rb`:

```ruby
RubyLLM.configure do |config|
  # Provider API Keys (only configure what you use)
  config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
  config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
  config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', nil)
  config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', nil)

  # AWS Bedrock (optional)
  # config.bedrock_api_key = ENV.fetch('AWS_ACCESS_KEY_ID', nil)
  # config.bedrock_secret_key = ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
  # config.bedrock_region = ENV.fetch('AWS_REGION', 'us-east-1')

  # Default Models
  config.default_model = ENV.fetch('ALOO_DEFAULT_MODEL', 'gemini-2.0-flash')
  config.default_embedding_model = ENV.fetch('ALOO_EMBEDDING_MODEL', 'text-embedding-3-small')

  # Connection Settings
  config.request_timeout = 120
  config.max_retries = 3
  config.retry_interval = 0.1
  config.retry_backoff_factor = 2

  # Logging
  if Rails.env.development?
    config.logger = Rails.logger
    config.log_level = :debug
  end
end
```

### ruby_llm-agents Setup

Run the generator:

```bash
rails generate ruby_llm_agents:install
rails db:migrate
```

This creates:
- `agent_executions` table for tracking
- `ApplicationAgent` base class
- Dashboard mounted at `/agents`

Mount the dashboard in `config/routes.rb`:

```ruby
mount RubyLLM::Agents::Engine, at: '/admin/agents' if Rails.env.development? || current_user&.administrator?
```

---

## Model Recommendations

### Chat Models by Use Case

| Use Case | Model | Provider | Why |
|----------|-------|----------|-----|
| **Customer Support (Default)** | `gemini-2.0-flash` | Google | Very fast, good quality, cheap |
| **Complex Reasoning** | `claude-sonnet-4` | Anthropic | Best instruction following |
| **Premium Support** | `gpt-4o` | OpenAI | Highest quality, vision |
| **Budget/High Volume** | `gpt-4o-mini` | OpenAI | Cheapest quality option |
| **Self-hosted** | `llama3.1:8b` | Ollama | Privacy, no data leaves server |

### Embedding Models

| Model | Dimensions | Best For |
|-------|------------|----------|
| `text-embedding-3-small` | 1536 | **Default** - Good balance |
| `text-embedding-3-large` | 3072 | Higher accuracy |

### Quick Reference

```ruby
# Customer conversations (fast, cheap)
RubyLLM.chat(model: 'gemini-2.0-flash')

# Complex reasoning
RubyLLM.chat(model: 'claude-sonnet-4')

# FAQ generation (bulk processing)
RubyLLM.chat(model: 'gpt-4o-mini')

# Embeddings
RubyLLM.embed(text, model: 'text-embedding-3-small')
```

---

## Personality & Language Configuration

### Configuration Separation

The assistant configuration is split into two categories:

| Category | Who Can Edit | What It Controls |
|----------|--------------|------------------|
| **Admin Settings** | Super Admin only | Model, temperature, API keys, tools, guardrails |
| **User Settings** | Account users | Personality, tone, language, greeting style |

### Personality Options

Users can customize their assistant's personality:

| Setting | Options | Description |
|---------|---------|-------------|
| **Tone** | `professional`, `friendly`, `casual`, `formal` | Overall communication style |
| **Formality** | `high`, `medium`, `low` | Level of formal language |
| **Empathy Level** | `high`, `medium`, `low` | How much emotional acknowledgment |
| **Verbosity** | `concise`, `balanced`, `detailed` | Response length preference |
| **Emoji Usage** | `none`, `minimal`, `moderate` | Whether to use emojis |
| **Greeting Style** | `warm`, `direct`, `custom` | How to start conversations |

### Arabic Dialect Support

Support for regional Arabic dialects based on country code:

| Country Code | Dialect | Example Greeting |
|--------------|---------|------------------|
| `EG` | Egyptian Arabic (مصري) | "أهلاً! إزيك؟ أقدر أساعدك في إيه؟" |
| `SA` | Saudi Arabic (سعودي) | "هلا والله! كيف أقدر أساعدك؟" |
| `AE` | Emirati Arabic (إماراتي) | "هلا! شو تبي أساعدك فيه؟" |
| `KW` | Kuwaiti Arabic (كويتي) | "هلا والله! شلونك؟ شنو تبي؟" |
| `QA` | Qatari Arabic (قطري) | "هلا! كيفك؟ شو بتحتاج؟" |
| `BH` | Bahraini Arabic (بحريني) | "هلا! شخبارك؟ شنو تبي؟" |
| `OM` | Omani Arabic (عماني) | "هلا! كيف حالك؟ شو تبي؟" |
| `JO` | Jordanian Arabic (أردني) | "مرحبا! كيفك؟ شو بتحتاج؟" |
| `LB` | Lebanese Arabic (لبناني) | "مرحبا! كيفك؟ شو فيني ساعدك؟" |
| `SY` | Syrian Arabic (سوري) | "مرحبا! كيفك؟ شو بدك؟" |
| `IQ` | Iraqi Arabic (عراقي) | "مرحبا! شلونك؟ شنو تريد؟" |
| `MA` | Moroccan Arabic (مغربي) | "السلام! لاباس؟ كيفاش نقدر نعاونك؟" |
| `DZ` | Algerian Arabic (جزائري) | "السلام عليكم! واش راك؟ كيفاش نعاونك؟" |
| `TN` | Tunisian Arabic (تونسي) | "أهلا! شنوا تحب؟" |
| `MSA` | Modern Standard Arabic | "مرحباً! كيف يمكنني مساعدتك؟" |

### Language Configuration

```ruby
# Supported languages with dialects
SUPPORTED_LANGUAGES = {
  'en' => { name: 'English', dialects: [] },
  'ar' => {
    name: 'Arabic',
    dialects: %w[EG SA AE KW QA BH OM JO LB SY IQ MA DZ TN MSA]
  },
  'fr' => { name: 'French', dialects: [] },
  'es' => { name: 'Spanish', dialects: [] },
  'de' => { name: 'German', dialects: [] },
  'pt' => { name: 'Portuguese', dialects: %w[BR PT] },
  'zh' => { name: 'Chinese', dialects: %w[CN TW] },
  'ja' => { name: 'Japanese', dialects: [] },
  'ko' => { name: 'Korean', dialects: [] },
  'hi' => { name: 'Hindi', dialects: [] },
  'tr' => { name: 'Turkish', dialects: [] }
}.freeze
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Aloo Agent System (Captain OSS)                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    ruby_llm-agents Framework                           │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐       │  │
│  │  │ ConversationAgent│  │ FaqGeneratorAgent│  │  IntentAgent    │       │  │
│  │  │ (chat responses)│  │ (auto FAQ)      │  │ (classify intent)│       │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘       │  │
│  │                                                                        │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │              Execution Tracking & Dashboard                      │  │  │
│  │  │  • Token usage  • Costs  • Latency  • Success rates             │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         Tools (MCPs)                                   │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │  │
│  │  │FaqLookupMcp  │ │HandoffMcp    │ │AddNoteMcp    │ │CustomHttpMcp │ │  │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘ │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    Knowledge Base (pgvector)                           │  │
│  │  • Documents (websites, files, Notion)                                 │  │
│  │  • Embeddings (1536-dim vectors, HNSW index)                          │  │
│  │  • Semantic search with cosine similarity                             │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Chatwoot Core (Existing)                             │
│  • Conversations  • Messages  • Inboxes  • Contacts  • Events               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation & Database Setup

### 1.1 Enable pgvector

```ruby
# db/migrate/XXXXXX_enable_pgvector.rb
class EnablePgvector < ActiveRecord::Migration[7.0]
  def up
    execute 'CREATE EXTENSION IF NOT EXISTS vector'
  end

  def down
    execute 'DROP EXTENSION IF EXISTS vector'
  end
end
```

### 1.2 Create Core Tables

```ruby
# db/migrate/XXXXXX_create_aloo_tables.rb
class CreateAlooTables < ActiveRecord::Migration[7.0]
  def change
    # Aloo Assistants - Main configuration
    create_table :aloo_assistants do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description

      # User-configurable: Personality & Language (users can edit)
      t.string :tone, default: 'friendly'           # professional, friendly, casual, formal
      t.string :formality, default: 'medium'        # high, medium, low
      t.string :empathy_level, default: 'medium'    # high, medium, low
      t.string :verbosity, default: 'balanced'      # concise, balanced, detailed
      t.string :emoji_usage, default: 'minimal'     # none, minimal, moderate
      t.string :greeting_style, default: 'warm'     # warm, direct, custom
      t.text :custom_greeting                       # Custom greeting message
      t.string :language, default: 'en'             # Language code (en, ar, fr, etc.)
      t.string :dialect                             # Dialect code (EG, SA, KW, etc.)
      t.text :personality_description               # Free-form personality description

      # Admin-only: Technical configuration (only admins can edit)
      t.text :system_prompt                         # Base system prompt
      t.text :response_guidelines                   # How to format responses
      t.text :guardrails                            # Safety rules
      t.jsonb :admin_config, default: {}            # model, temperature, max_tokens, etc.

      t.boolean :active, default: true
      t.timestamps
    end

    # Link assistants to inboxes
    create_table :aloo_assistant_inboxes do |t|
      t.references :aloo_assistant, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :aloo_assistant_inboxes, :inbox_id, unique: true

    # Documents - Knowledge base sources
    create_table :aloo_documents do |t|
      t.references :aloo_assistant, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.string :title
      t.string :source_type, null: false  # website, file, notion
      t.string :source_url
      t.text :content
      t.jsonb :metadata, default: {}
      t.integer :status, default: 0
      t.string :error_message
      t.timestamps
    end

    # Embeddings - Vector store
    create_table :aloo_embeddings do |t|
      t.references :aloo_assistant, null: false, foreign_key: true, index: true
      t.references :aloo_document, foreign_key: true, index: true
      t.text :content, null: false
      t.text :question
      t.vector :embedding, limit: 1536
      t.jsonb :metadata, default: {}
      t.integer :status, default: 0
      t.timestamps
    end

    # Custom Tools - HTTP integrations
    create_table :aloo_custom_tools do |t|
      t.references :aloo_assistant, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :endpoint_url
      t.string :http_method, default: 'POST'
      t.jsonb :parameters_schema, default: {}
      t.jsonb :headers, default: {}
      t.string :auth_type
      t.string :auth_credentials  # encrypted
      t.text :request_template
      t.text :response_template
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :aloo_custom_tools, [:aloo_assistant_id, :slug], unique: true

    # Conversation context tracking
    create_table :aloo_conversation_contexts do |t|
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }
      t.references :aloo_assistant, null: false, foreign_key: true
      t.jsonb :context_data, default: {}
      t.jsonb :tool_history, default: []
      t.integer :message_count, default: 0
      t.integer :input_tokens, default: 0
      t.integer :output_tokens, default: 0
      t.decimal :total_cost, precision: 10, scale: 6, default: 0
      t.timestamps
    end

    # Notion connections
    create_table :aloo_notion_connections do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :workspace_name
      t.string :workspace_id
      t.string :access_token  # encrypted
      t.string :bot_id
      t.datetime :token_expires_at
      t.jsonb :synced_pages, default: []
      t.datetime :last_synced_at
      t.timestamps
    end
  end
end
```

### 1.3 Add HNSW Vector Index

```ruby
# db/migrate/XXXXXX_add_hnsw_index_to_aloo_embeddings.rb
class AddHnswIndexToAlooEmbeddings < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE INDEX aloo_embeddings_embedding_idx
      ON aloo_embeddings
      USING hnsw (embedding vector_cosine_ops)
      WITH (m = 16, ef_construction = 64);
    SQL
  end

  def down
    execute 'DROP INDEX IF EXISTS aloo_embeddings_embedding_idx'
  end
end
```

### 1.4 Current Attributes for Context

`app/models/aloo/current.rb`:

```ruby
module Aloo
  class Current < ActiveSupport::CurrentAttributes
    attribute :account, :conversation, :assistant, :contact, :inbox

    def set_from_conversation(conversation)
      self.conversation = conversation
      self.account = conversation.account
      self.assistant = conversation.inbox.aloo_assistant
      self.contact = conversation.contact
      self.inbox = conversation.inbox
    end
  end
end
```

### 1.5 Assistant Model

`app/models/aloo/assistant.rb`:

```ruby
module Aloo
  class Assistant < ApplicationRecord
    self.table_name = 'aloo_assistants'

    belongs_to :account
    has_many :assistant_inboxes, class_name: 'Aloo::AssistantInbox', foreign_key: 'aloo_assistant_id', dependent: :destroy
    has_many :inboxes, through: :assistant_inboxes
    has_many :documents, class_name: 'Aloo::Document', foreign_key: 'aloo_assistant_id', dependent: :destroy
    has_many :embeddings, class_name: 'Aloo::Embedding', foreign_key: 'aloo_assistant_id', dependent: :destroy
    has_many :custom_tools, class_name: 'Aloo::CustomTool', foreign_key: 'aloo_assistant_id', dependent: :destroy
    has_many :conversation_contexts, class_name: 'Aloo::ConversationContext', foreign_key: 'aloo_assistant_id', dependent: :destroy

    # Personality settings (user-configurable)
    TONES = %w[professional friendly casual formal].freeze
    FORMALITY_LEVELS = %w[high medium low].freeze
    EMPATHY_LEVELS = %w[high medium low].freeze
    VERBOSITY_LEVELS = %w[concise balanced detailed].freeze
    EMOJI_USAGE_LEVELS = %w[none minimal moderate].freeze
    GREETING_STYLES = %w[warm direct custom].freeze

    # Arabic dialects by country
    ARABIC_DIALECTS = {
      'EG' => { name: 'Egyptian', prompt: 'Respond in Egyptian Arabic (مصري). Use Egyptian expressions and phrases.' },
      'SA' => { name: 'Saudi', prompt: 'Respond in Saudi Arabic (سعودي). Use Saudi expressions and phrases.' },
      'AE' => { name: 'Emirati', prompt: 'Respond in Emirati Arabic (إماراتي). Use Emirati expressions and phrases.' },
      'KW' => { name: 'Kuwaiti', prompt: 'Respond in Kuwaiti Arabic (كويتي). Use Kuwaiti expressions and phrases.' },
      'QA' => { name: 'Qatari', prompt: 'Respond in Qatari Arabic (قطري). Use Qatari expressions and phrases.' },
      'BH' => { name: 'Bahraini', prompt: 'Respond in Bahraini Arabic (بحريني). Use Bahraini expressions and phrases.' },
      'OM' => { name: 'Omani', prompt: 'Respond in Omani Arabic (عماني). Use Omani expressions and phrases.' },
      'JO' => { name: 'Jordanian', prompt: 'Respond in Jordanian Arabic (أردني). Use Jordanian expressions and phrases.' },
      'LB' => { name: 'Lebanese', prompt: 'Respond in Lebanese Arabic (لبناني). Use Lebanese expressions and phrases.' },
      'SY' => { name: 'Syrian', prompt: 'Respond in Syrian Arabic (سوري). Use Syrian expressions and phrases.' },
      'IQ' => { name: 'Iraqi', prompt: 'Respond in Iraqi Arabic (عراقي). Use Iraqi expressions and phrases.' },
      'MA' => { name: 'Moroccan', prompt: 'Respond in Moroccan Arabic (مغربي/دارجة). Use Moroccan expressions and phrases.' },
      'DZ' => { name: 'Algerian', prompt: 'Respond in Algerian Arabic (جزائري). Use Algerian expressions and phrases.' },
      'TN' => { name: 'Tunisian', prompt: 'Respond in Tunisian Arabic (تونسي). Use Tunisian expressions and phrases.' },
      'MSA' => { name: 'Modern Standard', prompt: 'Respond in Modern Standard Arabic (فصحى). Use formal, classical Arabic.' }
    }.freeze

    validates :name, presence: true
    validates :tone, inclusion: { in: TONES }
    validates :formality, inclusion: { in: FORMALITY_LEVELS }
    validates :empathy_level, inclusion: { in: EMPATHY_LEVELS }
    validates :verbosity, inclusion: { in: VERBOSITY_LEVELS }
    validates :emoji_usage, inclusion: { in: EMOJI_USAGE_LEVELS }
    validates :greeting_style, inclusion: { in: GREETING_STYLES }
    validates :dialect, inclusion: { in: ARABIC_DIALECTS.keys }, allow_blank: true

    scope :active, -> { where(active: true) }

    # Build the personality prompt based on user settings
    def personality_prompt
      Aloo::PersonalityBuilder.new(self).build
    end

    # Get the language instruction for the LLM
    def language_instruction
      return '' if language == 'en' && dialect.blank?

      if language == 'ar' && dialect.present?
        ARABIC_DIALECTS.dig(dialect, :prompt) || ''
      else
        "Respond in #{language_name}."
      end
    end

    def language_name
      Aloo::SUPPORTED_LANGUAGES.dig(language, :name) || 'English'
    end

    # Admin config accessors
    def model
      admin_config['model'] || 'gemini-2.0-flash'
    end

    def temperature
      admin_config['temperature'] || 0.7
    end

    def max_tokens
      admin_config['max_tokens'] || 1024
    end

    def feature_faq_enabled?
      admin_config['feature_faq'] == true
    end

    def feature_memory_enabled?
      admin_config['feature_memory'] == true
    end
  end
end
```

### 1.6 Personality Builder Service

`app/services/aloo/personality_builder.rb`:

```ruby
module Aloo
  class PersonalityBuilder
    TONE_PROMPTS = {
      'professional' => 'Maintain a professional and business-like tone. Be courteous and efficient.',
      'friendly' => 'Be warm, approachable, and conversational. Use a friendly tone that makes customers feel comfortable.',
      'casual' => 'Be relaxed and informal. Use casual language like you\'re chatting with a friend.',
      'formal' => 'Use formal language and proper etiquette. Be respectful and dignified in all responses.'
    }.freeze

    FORMALITY_PROMPTS = {
      'high' => 'Use formal greetings, proper titles, and avoid contractions or slang.',
      'medium' => 'Balance formal and informal language appropriately based on context.',
      'low' => 'Feel free to use contractions, casual expressions, and relaxed language.'
    }.freeze

    EMPATHY_PROMPTS = {
      'high' => 'Show strong empathy. Acknowledge customer emotions and frustrations explicitly. Use phrases like "I understand how frustrating this must be" or "I can see why you\'re concerned."',
      'medium' => 'Show appropriate empathy when customers express frustration or concern.',
      'low' => 'Focus on solutions rather than emotional acknowledgment. Be efficient and direct.'
    }.freeze

    VERBOSITY_PROMPTS = {
      'concise' => 'Keep responses brief and to the point. Avoid unnecessary details.',
      'balanced' => 'Provide enough detail to be helpful without being verbose.',
      'detailed' => 'Provide comprehensive, detailed responses with full explanations.'
    }.freeze

    EMOJI_PROMPTS = {
      'none' => 'Do not use any emojis in your responses.',
      'minimal' => 'Use emojis sparingly, only when they add warmth (like a greeting 👋 or thank you 🙏).',
      'moderate' => 'Feel free to use emojis to add personality and warmth to your responses.'
    }.freeze

    def initialize(assistant)
      @assistant = assistant
    end

    def build
      sections = []

      sections << "## Communication Style"
      sections << TONE_PROMPTS[@assistant.tone]
      sections << FORMALITY_PROMPTS[@assistant.formality]
      sections << EMPATHY_PROMPTS[@assistant.empathy_level]
      sections << VERBOSITY_PROMPTS[@assistant.verbosity]
      sections << EMOJI_PROMPTS[@assistant.emoji_usage]

      if @assistant.personality_description.present?
        sections << "\n## Additional Personality Traits"
        sections << @assistant.personality_description
      end

      if @assistant.language_instruction.present?
        sections << "\n## Language"
        sections << @assistant.language_instruction
      end

      if @assistant.greeting_style == 'custom' && @assistant.custom_greeting.present?
        sections << "\n## Greeting"
        sections << "When starting a conversation, use this greeting: \"#{@assistant.custom_greeting}\""
      end

      sections.compact.join("\n")
    end
  end
end
```

### 1.7 Supported Languages Constant

`app/models/aloo.rb`:

```ruby
module Aloo
  SUPPORTED_LANGUAGES = {
    'en' => { name: 'English', dialects: [] },
    'ar' => {
      name: 'Arabic',
      dialects: %w[EG SA AE KW QA BH OM JO LB SY IQ MA DZ TN MSA]
    },
    'fr' => { name: 'French', dialects: [] },
    'es' => { name: 'Spanish', dialects: [] },
    'de' => { name: 'German', dialects: [] },
    'pt' => { name: 'Portuguese', dialects: %w[BR PT] },
    'zh' => { name: 'Chinese', dialects: %w[CN TW] },
    'ja' => { name: 'Japanese', dialects: [] },
    'ko' => { name: 'Korean', dialects: [] },
    'hi' => { name: 'Hindi', dialects: [] },
    'tr' => { name: 'Turkish', dialects: [] }
  }.freeze
end
```

---

## Phase 2: Agent Framework

### 2.1 Base Agent (Extending ruby_llm-agents)

`app/agents/application_agent.rb`:

```ruby
class ApplicationAgent < RubyLLM::Agents::Base
  # Default configuration for all Chatwoot agents
  model 'gemini-2.0-flash'
  temperature 0.7
  version '1.0'

  # Access current context
  def current_context
    {
      account_id: Aloo::Current.account&.id,
      conversation_id: Aloo::Current.conversation&.id,
      contact_name: Aloo::Current.contact&.name,
      inbox_name: Aloo::Current.inbox&.name
    }
  end

  # Override to add custom metadata to executions
  def execution_metadata
    current_context
  end
end
```

### 2.2 Conversation Agent

`app/agents/conversation_agent.rb`:

```ruby
class ConversationAgent < ApplicationAgent
  # Model is determined by admin config, not hardcoded
  temperature 0.7
  version '1.0'
  timeout 30

  param :message, required: true
  param :conversation_id, required: true

  # Dynamic model based on assistant config
  def model
    Aloo::Current.assistant&.model || 'gemini-2.0-flash'
  end

  def system_prompt
    assistant = Aloo::Current.assistant
    knowledge_context = build_knowledge_context

    <<~PROMPT
      #{assistant&.system_prompt || default_system_prompt}

      #{assistant&.personality_prompt}

      #{assistant&.response_guidelines}

      #{assistant&.guardrails}

      ## Knowledge Base Context
      #{knowledge_context}

      ## Conversation Context
      - Contact: #{Aloo::Current.contact&.name || 'Unknown'}
      - Channel: #{Aloo::Current.inbox&.channel_type}

      ## Instructions
      - Use the faq_lookup tool when you need more information
      - Use the handoff tool to transfer to a human if needed
      - Keep responses relevant to the customer's question
    PROMPT
  end

  def user_prompt
    message
  end

  def tools
    [
      FaqLookupMcp,
      HandoffMcp,
      AddNoteMcp,
      UpdateConversationMcp,
      *custom_tools
    ]
  end

  private

  def default_system_prompt
    "You are a helpful customer support assistant. Help customers with their questions."
  end

  def build_knowledge_context
    return '' unless Aloo::Current.assistant

    search_service = Aloo::VectorSearchService.new(Aloo::Current.assistant)
    search_service.build_context(message, max_tokens: 2000)
  end

  def custom_tools
    return [] unless Aloo::Current.assistant

    Aloo::Current.assistant.custom_tools.active.map do |tool|
      Aloo::CustomToolBuilder.build(tool)
    end
  end
end
```

### 2.3 Intent Classification Agent

`app/agents/intent_agent.rb`:

```ruby
class IntentAgent < ApplicationAgent
  model 'gemini-2.0-flash'
  temperature 0.0  # Deterministic
  version '1.0'
  cache 1.hour

  param :message, required: true

  def system_prompt
    <<~PROMPT
      You are an intent classification system for customer support.
      Analyze the message and extract structured intent data.
      Return ONLY valid JSON matching the schema.
    PROMPT
  end

  def user_prompt
    "Classify this message: #{message}"
  end

  def schema
    @schema ||= RubyLLM::Schema.create do
      string :intent, enum: %w[question complaint request feedback greeting other]
      string :sentiment, enum: %w[positive neutral negative]
      string :urgency, enum: %w[low medium high urgent]
      array :topics, of: :string
      boolean :needs_human
      string :suggested_action
    end
  end
end
```

### 2.4 FAQ Generator Agent

`app/agents/faq_generator_agent.rb`:

```ruby
class FaqGeneratorAgent < ApplicationAgent
  model 'gpt-4o-mini'
  temperature 0.3
  version '1.0'

  param :transcript, required: true

  def system_prompt
    <<~PROMPT
      You are a FAQ extraction assistant. Analyze customer support conversations
      and extract clear question-answer pairs that would help other customers.

      Rules:
      - Only extract clear, complete Q&A pairs
      - Generalize questions (not specific to this customer)
      - Make answers standalone and complete
      - Skip greetings and small talk
      - Return empty array if no useful FAQ found
    PROMPT
  end

  def user_prompt
    "Extract FAQs from this conversation:\n\n#{transcript}"
  end

  def schema
    @schema ||= RubyLLM::Schema.create do
      array :faqs do
        string :question
        string :answer
        array :tags, of: :string
      end
    end
  end
end
```

---

## Phase 3: Knowledge Base & Embeddings

### 3.1 Embedding Concern

`app/models/concerns/aloo/embeddable.rb`:

```ruby
module Aloo
  module Embeddable
    extend ActiveSupport::Concern

    included do
      has_neighbors :embedding
      scope :with_embedding, -> { where.not(embedding: nil) }
    end

    class_methods do
      def semantic_search(query_embedding, limit: 5)
        with_embedding
          .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
          .limit(limit)
      end
    end

    def generate_embedding!
      return if content.blank?

      response = RubyLLM.embed(embedding_content, model: embedding_model)
      update!(embedding: response.vectors.first)
    end

    def embedding_content
      content
    end

    def embedding_model
      'text-embedding-3-small'
    end
  end
end
```

### 3.2 Aloo Embedding Model

`app/models/aloo/embedding.rb`:

```ruby
module Aloo
  class Embedding < ApplicationRecord
    include Aloo::Embeddable

    self.table_name = 'aloo_embeddings'

    belongs_to :assistant, class_name: 'Aloo::Assistant', foreign_key: 'aloo_assistant_id'
    belongs_to :document, class_name: 'Aloo::Document', foreign_key: 'aloo_document_id', optional: true

    enum :status, { pending: 0, approved: 1 }

    validates :content, presence: true

    scope :approved, -> { where(status: :approved) }
    scope :for_search, -> { approved.with_embedding }

    def embedding_content
      if question.present?
        "Question: #{question}\nAnswer: #{content}"
      else
        content
      end
    end

    # TOON format for LLM consumption
    def to_llm
      Toon.encode({
        id: id,
        q: question,
        a: content.truncate(500),
        src: document&.source_url
      })
    end
  end
end
```

### 3.3 Vector Search Service

`app/services/aloo/vector_search_service.rb`:

```ruby
module Aloo
  class VectorSearchService
    SIMILARITY_THRESHOLD = 0.3

    def initialize(assistant)
      @assistant = assistant
    end

    def search(query, limit: 5)
      query_embedding = generate_embedding(query)

      results = @assistant.embeddings
                          .for_search
                          .semantic_search(query_embedding, limit: limit)

      results.filter_map do |embedding|
        distance = embedding.neighbor_distance
        next if distance > SIMILARITY_THRESHOLD

        {
          id: embedding.id,
          content: embedding.content,
          question: embedding.question,
          source: embedding.document&.source_url || 'Manual',
          similarity: (1 - distance).round(3),
          title: embedding.document&.title
        }
      end
    end

    def build_context(query, max_tokens: 2000)
      results = search(query, limit: 10)
      return '' if results.empty?

      context = results.map do |r|
        if r[:question].present?
          "Q: #{r[:question]}\nA: #{r[:content]}"
        else
          r[:content]
        end
      end.join("\n\n---\n\n")

      context.truncate(max_tokens * 4, separator: "\n\n---\n\n")
    end

    private

    def generate_embedding(text)
      response = RubyLLM.embed(text, model: 'text-embedding-3-small')
      response.vectors.first
    end
  end
end
```

### 3.4 Embedding Service

`app/services/aloo/embedding_service.rb`:

```ruby
module Aloo
  class EmbeddingService
    CHUNK_SIZE = 1000
    CHUNK_OVERLAP = 200
    BATCH_SIZE = 20

    def initialize(assistant)
      @assistant = assistant
    end

    def create_embeddings_for_document(document)
      chunks = chunk_content(document.content)

      chunks.each_slice(BATCH_SIZE) do |batch|
        embeddings = RubyLLM.embed(batch, model: 'text-embedding-3-small')

        batch.each_with_index do |chunk, index|
          @assistant.embeddings.create!(
            document: document,
            content: chunk,
            embedding: embeddings.vectors[index],
            metadata: { chunk_index: index, source: document.source_url },
            status: :approved
          )
        end
      end
    end

    private

    def chunk_content(content)
      return [] if content.blank?

      chunks = []
      words = content.split
      current_chunk = []
      current_size = 0

      words.each do |word|
        if current_size + word.length > CHUNK_SIZE && current_chunk.any?
          chunks << current_chunk.join(' ')
          overlap_words = current_chunk.last(CHUNK_OVERLAP / 10)
          current_chunk = overlap_words
          current_size = overlap_words.join(' ').length
        end
        current_chunk << word
        current_size += word.length + 1
      end

      chunks << current_chunk.join(' ') if current_chunk.any?
      chunks
    end
  end
end
```

---

## Phase 4: Tools System (MCPs)

### 4.1 Base Tool

`app/mcps/base_mcp.rb`:

```ruby
class BaseMcp < RubyLLM::Tool
  # Access current context from Aloo::Current
  def current_account
    Aloo::Current.account
  end

  def current_conversation
    Aloo::Current.conversation
  end

  def current_assistant
    Aloo::Current.assistant
  end

  def current_contact
    Aloo::Current.contact
  end

  protected

  def log_execution(result)
    Rails.logger.info("[MCP] #{self.class.name}: #{result.to_json.truncate(500)}")
  end
end
```

### 4.2 FAQ Lookup Tool

`app/mcps/faq_lookup_mcp.rb`:

```ruby
class FaqLookupMcp < BaseMcp
  description "Search the knowledge base for relevant information to answer customer questions. Use this when you need additional context."

  param :query, type: :string, desc: "Search query for FAQ/documentation"

  def execute(query:)
    return { found: false, message: 'No assistant configured' } unless current_assistant

    search_service = Aloo::VectorSearchService.new(current_assistant)
    results = search_service.search(query, limit: 5)

    if results.empty?
      { found: false, message: 'No relevant information found' }
    else
      {
        found: true,
        results: results.map do |r|
          {
            content: r[:content],
            source: r[:source],
            relevance: "#{(r[:similarity] * 100).round}%"
          }
        end
      }
    end
  end
end
```

### 4.3 Handoff Tool

`app/mcps/handoff_mcp.rb`:

```ruby
class HandoffMcp < BaseMcp
  description "Transfer conversation to a human agent. Use when: customer requests human support, issue is complex, or you cannot help."

  param :reason, type: :string, desc: "Why the conversation is being transferred"
  param :priority, type: :string, desc: "Priority: low, medium, high, urgent", default: 'medium'

  def execute(reason:, priority: 'medium')
    conversation = current_conversation
    return { success: false, message: 'No conversation context' } unless conversation

    # Create internal note
    conversation.messages.create!(
      message_type: :activity,
      content: "Aloo Agent handoff: #{reason}",
      private: true,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id
    )

    # Update conversation
    priority_value = Conversation.priorities[priority] || Conversation.priorities[:medium]
    conversation.update!(
      status: :open,
      assignee: nil,
      priority: priority_value
    )

    # Dispatch event
    Rails.configuration.dispatcher.dispatch(
      'conversation.bot_handoff',
      Time.zone.now,
      conversation: conversation,
      reason: reason
    )

    log_execution({ success: true, reason: reason })

    # Halt to prevent follow-up message
    halt({ success: true, message: 'Transferred to human support' })
  end
end
```

### 4.4 Add Note Tool

`app/mcps/add_note_mcp.rb`:

```ruby
class AddNoteMcp < BaseMcp
  description "Add a private internal note visible only to human agents."

  param :note, type: :string, desc: "Content of the private note"

  def execute(note:)
    conversation = current_conversation
    return { success: false, message: 'No conversation context' } unless conversation

    conversation.messages.create!(
      message_type: :outgoing,
      content: note,
      private: true,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id
    )

    log_execution({ success: true })
    { success: true, message: 'Note added' }
  end
end
```

### 4.5 Update Conversation Tool

`app/mcps/update_conversation_mcp.rb`:

```ruby
class UpdateConversationMcp < BaseMcp
  description "Update conversation properties like labels or priority."

  param :add_labels, type: :array, desc: "Labels to add", items: { type: :string }
  param :priority, type: :string, desc: "Set priority: low, medium, high, urgent"

  def execute(add_labels: [], priority: nil)
    conversation = current_conversation
    return { success: false, message: 'No conversation context' } unless conversation

    actions = []

    # Add labels
    add_labels.each do |label_title|
      label = current_account.labels.find_by(title: label_title)
      if label && !conversation.labels.include?(label)
        conversation.labels << label
        actions << "Added label: #{label_title}"
      end
    end

    # Update priority
    if priority.present? && Conversation.priorities.key?(priority)
      conversation.update!(priority: priority)
      actions << "Set priority: #{priority}"
    end

    log_execution({ success: true, actions: actions })
    { success: true, actions: actions }
  end
end
```

### 4.6 Custom HTTP Tool Builder

`app/services/aloo/custom_tool_builder.rb`:

```ruby
module Aloo
  class CustomToolBuilder
    def self.build(custom_tool)
      Class.new(BaseMcp) do
        description custom_tool.description || "Custom tool: #{custom_tool.name}"

        # Build params from schema
        custom_tool.parameters_schema.each do |name, config|
          param name.to_sym,
                type: config['type']&.to_sym || :string,
                desc: config['description'] || name
        end

        define_method(:custom_tool) { custom_tool }

        define_method(:execute) do |**params|
          execute_http_request(params)
        end

        define_method(:execute_http_request) do |params|
          uri = URI.parse(custom_tool.endpoint_url)
          request = build_request(uri, params)
          add_auth_headers(request)
          add_context_headers(request)

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.open_timeout = 10
            http.read_timeout = 30
            http.request(request)
          end

          parse_response(response)
        rescue StandardError => e
          { error: e.message }
        end

        define_method(:build_request) do |uri, params|
          case custom_tool.http_method.upcase
          when 'GET'
            uri.query = URI.encode_www_form(params)
            Net::HTTP::Get.new(uri)
          when 'POST'
            req = Net::HTTP::Post.new(uri)
            req.body = render_template(params)
            req.content_type = 'application/json'
            req
          end
        end

        define_method(:add_auth_headers) do |request|
          case custom_tool.auth_type
          when 'bearer'
            request['Authorization'] = "Bearer #{custom_tool.auth_credentials}"
          when 'basic'
            creds = custom_tool.auth_credentials.split(':')
            request.basic_auth(creds[0], creds[1])
          when 'api_key'
            request['X-API-Key'] = custom_tool.auth_credentials
          end
        end

        define_method(:add_context_headers) do |request|
          request['X-Chatwoot-Account-ID'] = current_account&.id.to_s
          request['X-Chatwoot-Conversation-ID'] = current_conversation&.id.to_s
          request['X-Chatwoot-Contact-ID'] = current_contact&.id.to_s
        end

        define_method(:render_template) do |params|
          template = custom_tool.request_template
          return params.to_json if template.blank?

          Liquid::Template.parse(template).render(
            params.stringify_keys.merge(
              'conversation_id' => current_conversation&.id,
              'contact_email' => current_contact&.email,
              'contact_name' => current_contact&.name
            )
          )
        end

        define_method(:parse_response) do |response|
          if response.is_a?(Net::HTTPSuccess)
            body = JSON.parse(response.body) rescue response.body
            template = custom_tool.response_template
            if template.present?
              Liquid::Template.parse(template).render('response' => body)
            else
              body
            end
          else
            { error: "Request failed: #{response.code}" }
          end
        end
      end.new
    end
  end
end
```

---

## Phase 5: Onboarding & Data Ingestion

### 5.1 Website Crawler

`app/services/aloo/crawlers/website_crawler.rb`:

```ruby
module Aloo
  module Crawlers
    class WebsiteCrawler
      MAX_PAGES = 100
      MAX_DEPTH = 3

      def initialize(document)
        @document = document
        @visited = Set.new
        @base_uri = URI.parse(document.source_url)
      end

      def crawl
        @document.update!(status: :processing)

        pages = crawl_page(@document.source_url, 0)
        content = pages.map { |p| "# #{p[:title]}\n\n#{p[:content]}" }.join("\n\n---\n\n")

        @document.update!(
          content: content,
          status: :available,
          metadata: { pages_crawled: pages.count, urls: pages.pluck(:url) }
        )

        # Generate embeddings
        EmbeddingService.new(@document.assistant).create_embeddings_for_document(@document)
      rescue StandardError => e
        @document.update!(status: :failed, error_message: e.message)
        raise
      end

      private

      def crawl_page(url, depth)
        return [] if depth > MAX_DEPTH || @visited.size >= MAX_PAGES
        return [] if @visited.include?(url) || !same_domain?(url)

        @visited.add(url)
        response = fetch_page(url)
        return [] unless response

        doc = Nokogiri::HTML(response)
        content = extract_content(doc)
        title = doc.at_css('title')&.text&.strip || url

        pages = [{ url: url, title: title, content: content }]

        # Crawl links
        doc.css('a[href]').each do |link|
          href = resolve_url(link['href'])
          next unless href

          pages.concat(crawl_page(href, depth + 1))
          break if @visited.size >= MAX_PAGES
        end

        pages
      end

      def fetch_page(url)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = 10
        http.read_timeout = 10

        request = Net::HTTP::Get.new(uri)
        request['User-Agent'] = 'AlooBot/1.0'

        response = http.request(request)
        response.body if response.is_a?(Net::HTTPSuccess)
      rescue StandardError
        nil
      end

      def extract_content(doc)
        doc.css('script, style, nav, footer, header, aside').remove
        main = doc.at_css('main, article, .content, #content') || doc.at_css('body')
        main&.text&.gsub(/\s+/, ' ')&.strip || ''
      end

      def same_domain?(url)
        URI.parse(url).host == @base_uri.host
      rescue StandardError
        false
      end

      def resolve_url(href)
        return nil if href.blank? || href.start_with?('#', 'javascript:', 'mailto:')

        URI.join(@base_uri, href).to_s
      rescue StandardError
        nil
      end
    end
  end
end
```

### 5.2 File Processor

`app/services/aloo/processors/file_processor.rb`:

```ruby
module Aloo
  module Processors
    class FileProcessor
      def initialize(document)
        @document = document
      end

      def process
        @document.update!(status: :processing)

        content = case file_type
                  when :pdf then process_pdf
                  when :csv then process_csv
                  when :text then process_text
                  when :json then process_json
                  else raise "Unsupported: #{file_extension}"
                  end

        @document.update!(
          content: content,
          status: :available,
          title: @document.title || @document.file.filename.to_s
        )

        EmbeddingService.new(@document.assistant).create_embeddings_for_document(@document)
      rescue StandardError => e
        @document.update!(status: :failed, error_message: e.message)
        raise
      end

      private

      def file_type
        case file_extension
        when '.pdf' then :pdf
        when '.csv' then :csv
        when '.txt', '.md' then :text
        when '.json' then :json
        else :unknown
        end
      end

      def file_extension
        File.extname(@document.file.filename.to_s).downcase
      end

      def process_pdf
        require 'pdf-reader'
        reader = PDF::Reader.new(StringIO.new(@document.file.download))
        reader.pages.map(&:text).join("\n\n")
      end

      def process_csv
        require 'csv'
        csv = CSV.parse(@document.file.download, headers: true)
        csv.map { |row| row.to_h.map { |k, v| "#{k}: #{v}" }.join("\n") }.join("\n\n---\n\n")
      end

      def process_text
        @document.file.download.force_encoding('UTF-8')
      end

      def process_json
        JSON.pretty_generate(JSON.parse(@document.file.download))
      end
    end
  end
end
```

### 5.3 Notion Sync Service

`app/services/aloo/integrations/notion_sync_service.rb`:

```ruby
module Aloo
  module Integrations
    class NotionSyncService
      def initialize(connection, assistant)
        @connection = connection
        @assistant = assistant
        @client = Notion::Client.new(token: @connection.access_token)
      end

      def sync_all
        fetch_all_pages.each { |page_id| sync_page(page_id) }
        @connection.update!(last_synced_at: Time.current)
      end

      def sync_page(page_id)
        page = @client.page(page_id: page_id)
        blocks = fetch_all_blocks(page_id)
        content = blocks_to_text(blocks)
        title = extract_title(page)

        document = @assistant.documents.find_or_initialize_by(
          source_type: :notion,
          source_url: "notion://#{page_id}"
        )

        document.update!(
          account: @assistant.account,
          title: title,
          content: content,
          status: :available,
          metadata: { notion_page_id: page_id }
        )

        document.embeddings.destroy_all
        EmbeddingService.new(@assistant).create_embeddings_for_document(document)
      end

      private

      def fetch_all_pages
        results = []
        cursor = nil

        loop do
          response = @client.search(filter: { property: 'object', value: 'page' }, start_cursor: cursor)
          results.concat(response.results.map(&:id))
          break unless response.has_more

          cursor = response.next_cursor
        end

        results
      end

      def fetch_all_blocks(page_id)
        blocks = []
        cursor = nil

        loop do
          response = @client.block_children(block_id: page_id, start_cursor: cursor)
          response.results.each do |block|
            blocks << block
            blocks.concat(fetch_all_blocks(block.id)) if block.has_children
          end
          break unless response.has_more

          cursor = response.next_cursor
        end

        blocks
      end

      def blocks_to_text(blocks)
        blocks.filter_map do |block|
          case block.type
          when 'paragraph', 'heading_1', 'heading_2', 'heading_3'
            extract_rich_text(block.dig(block.type, :rich_text))
          when 'bulleted_list_item', 'numbered_list_item'
            "• #{extract_rich_text(block.dig(block.type, :rich_text))}"
          when 'code'
            "```\n#{extract_rich_text(block.dig(:code, :rich_text))}\n```"
          end
        end.join("\n\n")
      end

      def extract_rich_text(rich_text)
        rich_text&.map { |t| t[:plain_text] }&.join || ''
      end

      def extract_title(page)
        title_prop = page.properties.find { |_, v| v.type == 'title' }&.last
        title_prop&.title&.map { |t| t[:plain_text] }&.join || 'Untitled'
      end
    end
  end
end
```

### 5.4 Background Jobs

`app/jobs/aloo/process_document_job.rb`:

```ruby
module Aloo
  class ProcessDocumentJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(document_id)
      document = Aloo::Document.find(document_id)

      case document.source_type
      when 'website'
        Aloo::Crawlers::WebsiteCrawler.new(document).crawl
      when 'file'
        Aloo::Processors::FileProcessor.new(document).process
      when 'notion'
        connection = document.account.aloo_notion_connections.first
        raise 'No Notion connection' unless connection

        page_id = document.source_url.gsub('notion://', '')
        Aloo::Integrations::NotionSyncService.new(connection, document.assistant).sync_page(page_id)
      end
    end
  end
end
```

---

## Phase 6: Conversation Integration

### 6.1 Aloo Response Job

`app/jobs/aloo/response_job.rb`:

```ruby
module Aloo
  class ResponseJob < ApplicationJob
    queue_as :low

    def perform(conversation_id, message_id)
      conversation = Conversation.find(conversation_id)
      message = conversation.messages.find(message_id)

      return unless should_respond?(conversation, message)

      # Set context
      Aloo::Current.set_from_conversation(conversation)

      # Show typing
      broadcast_typing(conversation, true)

      begin
        # Call the agent
        result = ConversationAgent.call(
          message: message.content,
          conversation_id: conversation.id
        )

        # Create response message
        create_response(conversation, result.content) if result.content.present?

        # Track usage
        track_usage(conversation, result)
      ensure
        broadcast_typing(conversation, false)
      end
    end

    private

    def should_respond?(conversation, message)
      return false unless message.incoming?
      return false if message.private?
      return false if conversation.resolved? || conversation.snoozed?
      return false unless conversation.inbox.aloo_assistant&.active?
      return false if conversation.assignee.present? && !conversation.assignee.is_a?(Aloo::Assistant)

      true
    end

    def broadcast_typing(conversation, typing)
      event = typing ? 'typing_on' : 'typing_off'
      ActionCable.server.broadcast(
        "conversation:#{conversation.account_id}:#{conversation.id}",
        { event: event, user: { name: 'Aloo Assistant', type: 'ai' } }
      )
    end

    def create_response(conversation, content)
      conversation.messages.create!(
        message_type: :outgoing,
        content: content,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        sender: conversation.inbox.aloo_assistant
      )
    end

    def track_usage(conversation, result)
      context = conversation.aloo_conversation_context ||
                conversation.create_aloo_conversation_context!(aloo_assistant: Aloo::Current.assistant)

      context.message_count += 1
      context.input_tokens += result.input_tokens.to_i
      context.output_tokens += result.output_tokens.to_i
      # Cost is tracked automatically by ruby_llm-agents
      context.save!
    end
  end
end
```

### 6.2 Message Listener

`app/listeners/aloo_agent_listener.rb`:

```ruby
class AlooAgentListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    return unless should_trigger?(message, conversation)

    Aloo::ResponseJob.perform_later(conversation.id, message.id)
  end

  def conversation_resolved(event)
    conversation = event.data[:conversation]
    assistant = conversation.inbox.aloo_assistant

    return unless assistant&.effective_config&.dig('feature_faq')

    Aloo::FaqGeneratorJob.perform_later(conversation.id)
  end

  private

  def should_trigger?(message, conversation)
    message.incoming? &&
      !message.private? &&
      !conversation.resolved? &&
      !conversation.snoozed? &&
      conversation.inbox.aloo_assistant&.active? &&
      (conversation.assignee.blank? || conversation.assignee.is_a?(Aloo::Assistant))
  end
end
```

### 6.3 FAQ Generator Job

`app/jobs/aloo/faq_generator_job.rb`:

```ruby
module Aloo
  class FaqGeneratorJob < ApplicationJob
    queue_as :low

    def perform(conversation_id)
      conversation = Conversation.find(conversation_id)
      assistant = conversation.inbox.aloo_assistant

      return unless assistant
      return unless meaningful_exchange?(conversation)

      transcript = build_transcript(conversation)

      result = FaqGeneratorAgent.call(transcript: transcript)
      save_faqs(assistant, result.faqs, conversation.id) if result.faqs.present?
    rescue StandardError => e
      Rails.logger.error("[Aloo] FAQ generation failed: #{e.message}")
    end

    private

    def meaningful_exchange?(conversation)
      incoming = conversation.messages.where(message_type: :incoming).count
      outgoing = conversation.messages.where(message_type: :outgoing, private: false).count
      incoming >= 1 && outgoing >= 1
    end

    def build_transcript(conversation)
      conversation.messages
                  .where(private: false)
                  .order(:created_at)
                  .map { |m| "#{m.incoming? ? 'Customer' : 'Support'}: #{m.content}" }
                  .join("\n")
    end

    def save_faqs(assistant, faqs, conversation_id)
      faqs.each do |faq|
        next if faq['question'].blank? || faq['answer'].blank?
        next if duplicate?(assistant, faq['question'])

        embedding = RubyLLM.embed(faq['question'], model: 'text-embedding-3-small').vectors.first

        assistant.embeddings.create!(
          question: faq['question'],
          content: faq['answer'],
          embedding: embedding,
          status: :pending,
          metadata: { source: 'conversation', conversation_id: conversation_id }
        )
      end
    end

    def duplicate?(assistant, question)
      embedding = RubyLLM.embed(question, model: 'text-embedding-3-small').vectors.first
      similar = assistant.embeddings.for_search.semantic_search(embedding, limit: 1).first
      similar && similar.neighbor_distance < 0.2
    end
  end
end
```

---

## Phase 7: Frontend & Dashboard

### 7.1 Routes

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :accounts do
      resources :aloo_assistants do
        resources :documents, controller: 'aloo_assistants/documents'
        resources :embeddings, controller: 'aloo_assistants/embeddings', only: [:index, :create, :destroy]
        resources :custom_tools, controller: 'aloo_assistants/custom_tools'
        member do
          post :playground
          get :stats
        end
        collection do
          get :available_models
        end
      end
      resources :aloo_notion_connections, only: [:index, :create, :destroy] do
        member do
          post :sync
        end
      end
    end
  end
end

# Mount agent dashboard (admin only)
authenticate :user, ->(u) { u.administrator? } do
  mount RubyLLM::Agents::Engine, at: '/admin/agents'
end
```

### 7.2 Assistants Controller

`app/controllers/api/v1/accounts/aloo_assistants_controller.rb`:

```ruby
class Api::V1::Accounts::AlooAssistantsController < Api::V1::Accounts::BaseController
  before_action :set_assistant, only: [:show, :update, :destroy, :playground, :stats, :update_personality]
  before_action :require_admin, only: [:create, :destroy, :update_admin_config]

  def index
    @assistants = Current.account.aloo_assistants.includes(:inboxes)
    render json: @assistants
  end

  def show
    render json: @assistant, include: [:inboxes, :documents]
  end

  def create
    # Only admins can create assistants
    @assistant = Current.account.aloo_assistants.new(admin_params)
    if @assistant.save
      render json: @assistant, status: :created
    else
      render json: { errors: @assistant.errors }, status: :unprocessable_entity
    end
  end

  def update
    # Users can only update personality settings
    # Admins can update everything
    permitted = current_user.administrator? ? all_params : personality_params
    if @assistant.update(permitted)
      render json: @assistant
    else
      render json: { errors: @assistant.errors }, status: :unprocessable_entity
    end
  end

  # User-facing endpoint for personality settings only
  def update_personality
    if @assistant.update(personality_params)
      render json: @assistant
    else
      render json: { errors: @assistant.errors }, status: :unprocessable_entity
    end
  end

  # Admin-only endpoint for technical configuration
  def update_admin_config
    if @assistant.update(admin_config_params)
      render json: @assistant
    else
      render json: { errors: @assistant.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @assistant.destroy
    head :no_content
  end

  def playground
    Aloo::Current.assistant = @assistant
    result = ConversationAgent.call(
      message: params[:message],
      conversation_id: 0,
      dry_run: params[:dry_run]
    )
    render json: { response: result.content, tokens: result.total_tokens }
  end

  def stats
    contexts = @assistant.conversation_contexts

    executions = RubyLLM::Agents::Execution.where(
      "metadata->>'assistant_id' = ?", @assistant.id.to_s
    ).where(created_at: 30.days.ago..)

    render json: {
      conversations: contexts.count,
      messages: contexts.sum(:message_count),
      input_tokens: contexts.sum(:input_tokens),
      output_tokens: contexts.sum(:output_tokens),
      total_cost: contexts.sum(:total_cost),
      documents: @assistant.documents.available.count,
      embeddings: @assistant.embeddings.approved.count,
      success_rate: executions.success.count.to_f / [executions.count, 1].max,
      avg_latency_ms: executions.average(:duration_ms)
    }
  end

  # Get available personality options
  def personality_options
    render json: {
      tones: Aloo::Assistant::TONES,
      formality_levels: Aloo::Assistant::FORMALITY_LEVELS,
      empathy_levels: Aloo::Assistant::EMPATHY_LEVELS,
      verbosity_levels: Aloo::Assistant::VERBOSITY_LEVELS,
      emoji_usage_levels: Aloo::Assistant::EMOJI_USAGE_LEVELS,
      greeting_styles: Aloo::Assistant::GREETING_STYLES,
      languages: Aloo::SUPPORTED_LANGUAGES,
      arabic_dialects: Aloo::Assistant::ARABIC_DIALECTS.transform_values { |v| v[:name] }
    }
  end

  # Admin-only: Get available models
  def available_models
    return head :forbidden unless current_user.administrator?

    models = RubyLLM.models.chat_models.map do |m|
      { id: m.id, provider: m.provider, supports_tools: m.supports_tools? }
    end
    render json: { models: models }
  end

  private

  def set_assistant
    @assistant = Current.account.aloo_assistants.find(params[:id])
  end

  def require_admin
    head :forbidden unless current_user.administrator?
  end

  # Personality settings - users can edit
  def personality_params
    params.require(:aloo_assistant).permit(
      :name,
      :description,
      :tone,
      :formality,
      :empathy_level,
      :verbosity,
      :emoji_usage,
      :greeting_style,
      :custom_greeting,
      :language,
      :dialect,
      :personality_description
    )
  end

  # Admin-only settings
  def admin_config_params
    params.require(:aloo_assistant).permit(
      :system_prompt,
      :response_guidelines,
      :guardrails,
      :active,
      admin_config: [:model, :embedding_model, :temperature, :max_tokens, :feature_faq, :feature_memory],
      inbox_ids: []
    )
  end

  # All params for admin create/update
  def all_params
    personality_params.merge(admin_config_params)
  end

  # Initial creation params (admin only)
  def admin_params
    params.require(:aloo_assistant).permit(
      :name, :description, :active,
      # Personality (with defaults)
      :tone, :formality, :empathy_level, :verbosity, :emoji_usage,
      :greeting_style, :custom_greeting, :language, :dialect, :personality_description,
      # Admin config
      :system_prompt, :response_guidelines, :guardrails,
      admin_config: [:model, :embedding_model, :temperature, :max_tokens, :feature_faq, :feature_memory],
      inbox_ids: []
    )
  end
end
```

### 7.3 Updated Routes

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :accounts do
      resources :aloo_assistants do
        resources :documents, controller: 'aloo_assistants/documents'
        resources :embeddings, controller: 'aloo_assistants/embeddings', only: [:index, :create, :destroy]
        resources :custom_tools, controller: 'aloo_assistants/custom_tools'
        member do
          post :playground
          get :stats
          patch :update_personality      # User can edit
          patch :update_admin_config     # Admin only
        end
        collection do
          get :personality_options       # Get available options
          get :available_models          # Admin only
        end
      end
      resources :aloo_notion_connections, only: [:index, :create, :destroy] do
        member do
          post :sync
        end
      end
    end
  end
end
```

### 7.4 Frontend Components

Create Vue components in `app/javascript/dashboard/routes/dashboard/settings/alooAssistants/`:

1. **Index.vue** - List assistants with stats
2. **Create.vue** - New assistant wizard (admin only)
3. **EditPersonality.vue** - Edit personality settings (all users)
4. **EditAdmin.vue** - Edit technical settings (admin only)
5. **Documents.vue** - Manage knowledge base
6. **Playground.vue** - Test responses
7. **CustomTools.vue** - Configure HTTP tools (admin only)
8. **Stats.vue** - Analytics dashboard

### 7.5 Personality Settings Component

`app/javascript/dashboard/routes/dashboard/settings/alooAssistants/EditPersonality.vue`:

```vue
<template>
  <div class="flex flex-col gap-6 p-6">
    <h2 class="text-xl font-semibold">Customize Assistant Personality</h2>

    <!-- Tone -->
    <div>
      <label class="block text-sm font-medium mb-2">Tone</label>
      <select v-model="assistant.tone" class="w-full border rounded-lg p-2">
        <option value="professional">Professional</option>
        <option value="friendly">Friendly</option>
        <option value="casual">Casual</option>
        <option value="formal">Formal</option>
      </select>
    </div>

    <!-- Formality -->
    <div>
      <label class="block text-sm font-medium mb-2">Formality Level</label>
      <select v-model="assistant.formality" class="w-full border rounded-lg p-2">
        <option value="high">High</option>
        <option value="medium">Medium</option>
        <option value="low">Low</option>
      </select>
    </div>

    <!-- Empathy -->
    <div>
      <label class="block text-sm font-medium mb-2">Empathy Level</label>
      <select v-model="assistant.empathy_level" class="w-full border rounded-lg p-2">
        <option value="high">High - Acknowledge emotions explicitly</option>
        <option value="medium">Medium - Appropriate empathy</option>
        <option value="low">Low - Focus on solutions</option>
      </select>
    </div>

    <!-- Verbosity -->
    <div>
      <label class="block text-sm font-medium mb-2">Response Length</label>
      <select v-model="assistant.verbosity" class="w-full border rounded-lg p-2">
        <option value="concise">Concise - Brief responses</option>
        <option value="balanced">Balanced - Normal length</option>
        <option value="detailed">Detailed - Comprehensive</option>
      </select>
    </div>

    <!-- Emoji Usage -->
    <div>
      <label class="block text-sm font-medium mb-2">Emoji Usage</label>
      <select v-model="assistant.emoji_usage" class="w-full border rounded-lg p-2">
        <option value="none">None</option>
        <option value="minimal">Minimal</option>
        <option value="moderate">Moderate</option>
      </select>
    </div>

    <!-- Language -->
    <div>
      <label class="block text-sm font-medium mb-2">Language</label>
      <select v-model="assistant.language" class="w-full border rounded-lg p-2">
        <option value="en">English</option>
        <option value="ar">Arabic</option>
        <option value="fr">French</option>
        <option value="es">Spanish</option>
        <!-- ... other languages -->
      </select>
    </div>

    <!-- Arabic Dialect (shown when Arabic is selected) -->
    <div v-if="assistant.language === 'ar'">
      <label class="block text-sm font-medium mb-2">Arabic Dialect</label>
      <select v-model="assistant.dialect" class="w-full border rounded-lg p-2">
        <option value="EG">Egyptian (مصري)</option>
        <option value="SA">Saudi (سعودي)</option>
        <option value="AE">Emirati (إماراتي)</option>
        <option value="KW">Kuwaiti (كويتي)</option>
        <option value="QA">Qatari (قطري)</option>
        <option value="BH">Bahraini (بحريني)</option>
        <option value="OM">Omani (عماني)</option>
        <option value="JO">Jordanian (أردني)</option>
        <option value="LB">Lebanese (لبناني)</option>
        <option value="SY">Syrian (سوري)</option>
        <option value="IQ">Iraqi (عراقي)</option>
        <option value="MA">Moroccan (مغربي)</option>
        <option value="DZ">Algerian (جزائري)</option>
        <option value="TN">Tunisian (تونسي)</option>
        <option value="MSA">Modern Standard (فصحى)</option>
      </select>
    </div>

    <!-- Custom Greeting -->
    <div>
      <label class="block text-sm font-medium mb-2">Greeting Style</label>
      <select v-model="assistant.greeting_style" class="w-full border rounded-lg p-2">
        <option value="warm">Warm</option>
        <option value="direct">Direct</option>
        <option value="custom">Custom</option>
      </select>
    </div>

    <div v-if="assistant.greeting_style === 'custom'">
      <label class="block text-sm font-medium mb-2">Custom Greeting</label>
      <textarea
        v-model="assistant.custom_greeting"
        class="w-full border rounded-lg p-2"
        rows="2"
        placeholder="Enter your custom greeting message..."
      />
    </div>

    <!-- Personality Description -->
    <div>
      <label class="block text-sm font-medium mb-2">Additional Personality Traits</label>
      <textarea
        v-model="assistant.personality_description"
        class="w-full border rounded-lg p-2"
        rows="3"
        placeholder="Describe any additional personality traits..."
      />
    </div>

    <button
      @click="save"
      class="bg-blue-600 text-white px-4 py-2 rounded-lg"
    >
      Save Changes
    </button>
  </div>
</template>
```

---

## Phase 8: Advanced Features

### 8.1 Contact Memory Service

`app/services/aloo/contact_memory_service.rb`:

```ruby
module Aloo
  class ContactMemoryService
    def initialize(contact)
      @contact = contact
    end

    def build_context
      {
        name: @contact.name,
        email: @contact.email,
        phone: @contact.phone_number,
        custom_attributes: @contact.custom_attributes,
        recent_notes: recent_notes,
        conversation_summary: conversation_summary
      }
    end

    def add_insight(conversation)
      return unless conversation.resolved? && conversation.messages.count >= 3

      transcript = conversation.messages
                               .where(private: false)
                               .order(:created_at)
                               .map { |m| "#{m.incoming? ? 'Customer' : 'Support'}: #{m.content}" }
                               .join("\n")

      result = ContactInsightAgent.call(transcript: transcript)
      return if result.insight.blank?

      @contact.notes.create!(
        content: "[Aloo Insight] #{result.insight}",
        account_id: @contact.account_id
      )
    end

    private

    def recent_notes
      @contact.notes.order(created_at: :desc).limit(5).pluck(:content)
    end

    def conversation_summary
      @contact.conversations.order(created_at: :desc).limit(5).map do |conv|
        { id: conv.display_id, status: conv.status, labels: conv.labels.pluck(:title) }
      end
    end
  end
end
```

### 8.2 Vision Support

`app/services/aloo/vision_service.rb`:

```ruby
module Aloo
  class VisionService
    def analyze_image(image_path_or_url, context: nil)
      chat = RubyLLM.chat(model: 'gpt-4o')

      prompt = context ?
        "Customer shared this image. Context: #{context}\n\nDescribe and assist." :
        "Customer shared this image. Describe what you see and ask how to help."

      response = chat.ask(prompt, with: image_path_or_url)
      response.content
    rescue StandardError => e
      Rails.logger.error("[Aloo] Vision analysis failed: #{e.message}")
      nil
    end
  end
end
```

### 8.3 Audio Transcription

`app/services/aloo/audio_service.rb`:

```ruby
module Aloo
  class AudioService
    def transcribe(audio_file_path)
      response = RubyLLM.transcribe(audio_file_path)
      response.text
    rescue StandardError => e
      Rails.logger.error("[Aloo] Transcription failed: #{e.message}")
      nil
    end
  end
end
```

---

## Configuration Summary

### Environment Variables

```bash
# LLM Providers
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=...
DEEPSEEK_API_KEY=...

# Defaults
ALOO_DEFAULT_MODEL=gemini-2.0-flash
ALOO_EMBEDDING_MODEL=text-embedding-3-small

# Notion (optional)
NOTION_CLIENT_ID=...
NOTION_CLIENT_SECRET=...
NOTION_REDIRECT_URI=https://your-app.com/oauth/notion/callback
```

### Feature Flags

```yaml
aloo:
  enabled: true
  auto_faq_generation: true
  contact_memory: false
  vision_support: true
```

---

## Key Benefits of This Architecture

1. **ruby_llm-agents** provides:
   - Built-in execution tracking
   - Cost analytics dashboard
   - Token usage monitoring
   - Caching with TTL
   - Structured output schemas

2. **Agent Pattern** (from asatok):
   - Declarative DSL for configuration
   - Version-based cache invalidation
   - Automatic instrumentation
   - Timeout protection

3. **MCP Tools** (from rivalbird):
   - Clean tool abstraction
   - Context via `Aloo::Current`
   - Easy to add custom tools

4. **HNSW Vector Index**:
   - Fast similarity search
   - Scales to millions of embeddings

5. **TOON Serialization**:
   - Token-efficient encoding for LLM
   - Reduces costs on large responses

6. **Personality & Language System**:
   - User-configurable personality settings
   - Arabic dialect support (15 regional dialects)
   - Separation of admin vs user permissions
   - Dynamic prompt generation based on settings

---

## Models Summary

| Model | Table | Description |
|-------|-------|-------------|
| `Aloo::Assistant` | `aloo_assistants` | Main configuration for AI agent |
| `Aloo::Document` | `aloo_documents` | Knowledge base sources (website, file, notion) |
| `Aloo::Embedding` | `aloo_embeddings` | Vector embeddings for semantic search |
| `Aloo::CustomTool` | `aloo_custom_tools` | HTTP tool integrations |
| `Aloo::ConversationContext` | `aloo_conversation_contexts` | Tracks AI usage per conversation |
| `Aloo::NotionConnection` | `aloo_notion_connections` | Notion OAuth credentials |
| `Aloo::AssistantInbox` | `aloo_assistant_inboxes` | Links assistants to inboxes |

---

## Assistant Configuration Fields

### User-Configurable (Personality & Language)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `tone` | string | `friendly` | Communication style (professional, friendly, casual, formal) |
| `formality` | string | `medium` | Formality level (high, medium, low) |
| `empathy_level` | string | `medium` | Emotional acknowledgment (high, medium, low) |
| `verbosity` | string | `balanced` | Response length (concise, balanced, detailed) |
| `emoji_usage` | string | `minimal` | Emoji usage (none, minimal, moderate) |
| `greeting_style` | string | `warm` | Greeting approach (warm, direct, custom) |
| `custom_greeting` | text | null | Custom greeting message |
| `language` | string | `en` | Response language code |
| `dialect` | string | null | Regional dialect (e.g., EG, KW, SA for Arabic) |
| `personality_description` | text | null | Free-form personality traits |

### Admin-Only (Technical)

| Field | Type | Description |
|-------|------|-------------|
| `system_prompt` | text | Base system instructions |
| `response_guidelines` | text | How to format responses |
| `guardrails` | text | Safety and compliance rules |
| `admin_config` | jsonb | Model, temperature, max_tokens, features |
| `active` | boolean | Enable/disable the assistant |

# AI Agent Implementation Plan (Captain OSS Alternative)

This document outlines the implementation plan for creating an AI agent system in the open-source version of Chatwoot, replicating the functionality of the Enterprise "Captain" feature using the [RubyLLM](https://rubyllm.com) gem.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Phase 1: Foundation & Database Setup](#phase-1-foundation--database-setup)
4. [Phase 2: Knowledge Base & Embedding System](#phase-2-knowledge-base--embedding-system)
5. [Phase 3: Onboarding & Data Ingestion](#phase-3-onboarding--data-ingestion)
6. [Phase 4: AI Agent Core](#phase-4-ai-agent-core)
7. [Phase 5: Tools System](#phase-5-tools-system)
8. [Phase 6: Conversation Integration](#phase-6-conversation-integration)
9. [Phase 7: Frontend & Management UI](#phase-7-frontend--management-ui)
10. [Phase 8: Advanced Features](#phase-8-advanced-features)

---

## Overview

### Goals

- Create an AI agent system that can handle customer conversations autonomously
- Support multiple knowledge sources: websites, files (PDF, CSV), and Notion integration
- Use vector embeddings for semantic search and context retrieval
- Implement a flexible tools system using RubyLLM for agent capabilities
- Integrate seamlessly with existing Chatwoot conversation flow

### Tech Stack

- **LLM Integration**: RubyLLM gem
- **Vector Database**: PostgreSQL with pgvector extension
- **Embeddings**: OpenAI text-embedding-3-small (1536 dimensions)
- **Web Scraping**: Nokogiri + custom crawler
- **PDF Processing**: pdf-reader gem
- **CSV Processing**: Ruby CSV standard library
- **Notion Integration**: notion-ruby-client gem
- **Background Jobs**: Sidekiq (existing)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AI Agent System                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐       │
│  │   Onboarding     │    │  Knowledge Base  │    │   AI Agent Core  │       │
│  │                  │    │                  │    │                  │       │
│  │ • Website Crawler│───▶│ • Documents      │───▶│ • Chat Service   │       │
│  │ • File Uploader  │    │ • Embeddings     │    │ • Tool Executor  │       │
│  │ • Notion Sync    │    │ • Vector Search  │    │ • Response Gen   │       │
│  └──────────────────┘    └──────────────────┘    └──────────────────┘       │
│           │                       │                       │                  │
│           ▼                       ▼                       ▼                  │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                         PostgreSQL + pgvector                     │       │
│  │  • ai_assistants  • ai_documents  • ai_embeddings  • ai_tools    │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                    RubyLLM Tools System                           │       │
│  │  • FaqLookupTool  • HandoffTool  • AddNoteTool  • Custom Tools   │       │
│  └──────────────────────────────────────────────────────────────────┘       │
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

### 1.1 Install Dependencies

Add to `Gemfile`:

```ruby
# AI Agent Dependencies
gem 'ruby_llm', '~> 1.2'           # LLM integration
gem 'neighbor', '~> 0.5'            # pgvector Rails integration
gem 'pdf-reader', '~> 2.12'         # PDF parsing
gem 'notion-ruby-client', '~> 1.3'  # Notion API
gem 'robots', '~> 0.10'             # robots.txt parser for crawling
```

### 1.2 Enable pgvector Extension

Create migration: `db/migrate/XXXXXX_enable_pgvector.rb`

```ruby
class EnablePgvector < ActiveRecord::Migration[7.0]
  def up
    execute 'CREATE EXTENSION IF NOT EXISTS vector'
  end

  def down
    execute 'DROP EXTENSION IF EXISTS vector'
  end
end
```

### 1.3 Create Core Tables

Migration: `db/migrate/XXXXXX_create_ai_agent_tables.rb`

```ruby
class CreateAiAgentTables < ActiveRecord::Migration[7.0]
  def change
    # AI Assistants - Main configuration for each AI agent
    create_table :ai_assistants do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.text :system_prompt
      t.text :response_guidelines
      t.text :guardrails
      t.jsonb :config, default: {}  # temperature, model, features
      t.boolean :active, default: true
      t.timestamps
    end

    # AI Assistant Inboxes - Link assistants to inboxes
    create_table :ai_assistant_inboxes do |t|
      t.references :ai_assistant, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :ai_assistant_inboxes, :inbox_id, unique: true

    # AI Documents - Knowledge base sources
    create_table :ai_documents do |t|
      t.references :ai_assistant, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.string :title
      t.string :source_type, null: false  # website, file, notion
      t.string :source_url
      t.text :content
      t.jsonb :metadata, default: {}
      t.integer :status, default: 0  # pending, processing, available, failed
      t.string :error_message
      t.timestamps
    end

    # AI Embeddings - Vector embeddings for semantic search
    create_table :ai_embeddings do |t|
      t.references :ai_assistant, null: false, foreign_key: true, index: true
      t.references :ai_document, foreign_key: true, index: true
      t.text :content, null: false
      t.text :question  # For FAQ-style embeddings
      t.vector :embedding, limit: 1536  # OpenAI embedding dimension
      t.jsonb :metadata, default: {}
      t.integer :status, default: 0  # pending, approved
      t.timestamps
    end

    # AI Custom Tools - User-defined HTTP tools
    create_table :ai_custom_tools do |t|
      t.references :ai_assistant, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :endpoint_url
      t.string :http_method, default: 'POST'
      t.jsonb :parameters_schema, default: {}
      t.jsonb :headers, default: {}
      t.string :auth_type  # none, bearer, basic, api_key
      t.string :auth_credentials  # encrypted
      t.text :request_template
      t.text :response_template
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :ai_custom_tools, [:ai_assistant_id, :slug], unique: true

    # AI Conversation Contexts - Track AI context per conversation
    create_table :ai_conversation_contexts do |t|
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }
      t.references :ai_assistant, null: false, foreign_key: true
      t.jsonb :context_data, default: {}
      t.jsonb :tool_history, default: []
      t.integer :message_count, default: 0
      t.timestamps
    end

    # Notion Connections - Store Notion OAuth tokens
    create_table :ai_notion_connections do |t|
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

### 1.4 Add Vector Index

Migration: `db/migrate/XXXXXX_add_vector_index_to_ai_embeddings.rb`

```ruby
class AddVectorIndexToAiEmbeddings < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE INDEX ai_embeddings_embedding_idx
      ON ai_embeddings
      USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 100);
    SQL
  end

  def down
    execute 'DROP INDEX IF EXISTS ai_embeddings_embedding_idx'
  end
end
```

### 1.5 Create Models

#### `app/models/ai_assistant.rb`

```ruby
class AiAssistant < ApplicationRecord
  belongs_to :account
  has_many :ai_assistant_inboxes, dependent: :destroy
  has_many :inboxes, through: :ai_assistant_inboxes
  has_many :ai_documents, dependent: :destroy
  has_many :ai_embeddings, dependent: :destroy
  has_many :ai_custom_tools, dependent: :destroy
  has_many :ai_conversation_contexts, dependent: :destroy

  validates :name, presence: true
  validates :account_id, presence: true

  # Default config values
  DEFAULT_CONFIG = {
    'model' => 'gpt-4o',
    'temperature' => 0.7,
    'max_tokens' => 1024,
    'feature_faq' => true,
    'feature_memory' => false
  }.freeze

  def effective_config
    DEFAULT_CONFIG.merge(config || {})
  end

  def temperature
    effective_config['temperature']
  end

  def model
    effective_config['model']
  end
end
```

#### `app/models/ai_document.rb`

```ruby
class AiDocument < ApplicationRecord
  belongs_to :ai_assistant
  belongs_to :account
  has_many :ai_embeddings, dependent: :destroy
  has_one_attached :file

  enum :status, { pending: 0, processing: 1, available: 2, failed: 3 }
  enum :source_type, { website: 'website', file: 'file', notion: 'notion' }

  validates :source_type, presence: true
  validates :source_url, presence: true, if: -> { website? || notion? }
  validates :file, presence: true, if: :file?

  after_create_commit :schedule_processing

  private

  def schedule_processing
    AiDocuments::ProcessJob.perform_later(id)
  end
end
```

#### `app/models/ai_embedding.rb`

```ruby
class AiEmbedding < ApplicationRecord
  belongs_to :ai_assistant
  belongs_to :ai_document, optional: true

  has_neighbors :embedding

  enum :status, { pending: 0, approved: 1 }

  validates :content, presence: true

  scope :approved, -> { where(status: :approved) }
  scope :for_search, -> { approved.where.not(embedding: nil) }

  def self.semantic_search(query_embedding, limit: 5)
    for_search.nearest_neighbors(:embedding, query_embedding, distance: 'cosine').limit(limit)
  end
end
```

#### `app/models/ai_custom_tool.rb`

```ruby
class AiCustomTool < ApplicationRecord
  belongs_to :ai_assistant
  belongs_to :account

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :ai_assistant_id }
  validates :endpoint_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

  before_validation :generate_slug

  enum :auth_type, { none: 'none', bearer: 'bearer', basic: 'basic', api_key: 'api_key' }

  encrypts :auth_credentials

  private

  def generate_slug
    self.slug ||= name&.parameterize&.underscore
  end
end
```

---

## Phase 2: Knowledge Base & Embedding System

### 2.1 Embedding Service

`app/services/ai_agent/embedding_service.rb`

```ruby
module AiAgent
  class EmbeddingService
    EMBEDDING_MODEL = 'text-embedding-3-small'
    CHUNK_SIZE = 1000
    CHUNK_OVERLAP = 200

    def initialize(ai_assistant)
      @ai_assistant = ai_assistant
    end

    def create_embeddings_for_document(document)
      chunks = chunk_content(document.content)

      chunks.each_with_index do |chunk, index|
        embedding_vector = generate_embedding(chunk)

        @ai_assistant.ai_embeddings.create!(
          ai_document: document,
          content: chunk,
          embedding: embedding_vector,
          metadata: { chunk_index: index, source: document.source_url },
          status: :approved
        )
      end
    end

    def generate_embedding(text)
      response = RubyLLM.embed(text, model: EMBEDDING_MODEL)
      response.vectors.first
    end

    def search(query, limit: 5)
      query_embedding = generate_embedding(query)
      @ai_assistant.ai_embeddings.semantic_search(query_embedding, limit: limit)
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
          # Keep overlap
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

### 2.2 Vector Search Service

`app/services/ai_agent/vector_search_service.rb`

```ruby
module AiAgent
  class VectorSearchService
    def initialize(ai_assistant)
      @ai_assistant = ai_assistant
      @embedding_service = EmbeddingService.new(ai_assistant)
    end

    def search(query, limit: 5, threshold: 0.3)
      results = @embedding_service.search(query, limit: limit)

      # Filter by similarity threshold and format results
      results.filter_map do |embedding|
        distance = embedding.neighbor_distance
        next if distance > threshold

        {
          content: embedding.content,
          question: embedding.question,
          source: embedding.ai_document&.source_url || 'Manual entry',
          similarity: 1 - distance,
          document_title: embedding.ai_document&.title
        }
      end
    end

    def build_context(query, max_tokens: 2000)
      results = search(query, limit: 10)

      context = results.map do |r|
        if r[:question].present?
          "Q: #{r[:question]}\nA: #{r[:content]}"
        else
          r[:content]
        end
      end.join("\n\n---\n\n")

      # Truncate if too long (rough estimation)
      context.truncate(max_tokens * 4, separator: "\n\n---\n\n")
    end
  end
end
```

---

## Phase 3: Onboarding & Data Ingestion

### 3.1 Website Crawler Service

`app/services/ai_agent/crawlers/website_crawler.rb`

```ruby
module AiAgent
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
        EmbeddingService.new(@document.ai_assistant).create_embeddings_for_document(@document)
      rescue StandardError => e
        @document.update!(status: :failed, error_message: e.message)
        raise
      end

      private

      def crawl_page(url, depth)
        return [] if depth > MAX_DEPTH || @visited.size >= MAX_PAGES || @visited.include?(url)
        return [] unless same_domain?(url)

        @visited.add(url)

        response = fetch_page(url)
        return [] unless response

        doc = Nokogiri::HTML(response)
        content = extract_content(doc)
        title = doc.at_css('title')&.text&.strip || url

        pages = [{ url: url, title: title, content: content }]

        # Find and crawl links
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
        response = Net::HTTP.get_response(uri)
        response.body if response.is_a?(Net::HTTPSuccess)
      rescue StandardError
        nil
      end

      def extract_content(doc)
        # Remove script, style, nav, footer elements
        doc.css('script, style, nav, footer, header, aside').remove

        # Get main content
        main = doc.at_css('main, article, .content, #content, .main') || doc.at_css('body')
        return '' unless main

        main.text.gsub(/\s+/, ' ').strip
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

### 3.2 File Processor Service

`app/services/ai_agent/processors/file_processor.rb`

```ruby
module AiAgent
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
                  else
                    raise "Unsupported file type: #{file_extension}"
                  end

        @document.update!(
          content: content,
          status: :available,
          title: @document.title || @document.file.filename.to_s
        )

        # Generate embeddings
        EmbeddingService.new(@document.ai_assistant).create_embeddings_for_document(@document)
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
        else :unknown
        end
      end

      def file_extension
        File.extname(@document.file.filename.to_s).downcase
      end

      def process_pdf
        reader = PDF::Reader.new(@document.file.download)
        reader.pages.map(&:text).join("\n\n")
      end

      def process_csv
        content = @document.file.download
        csv = CSV.parse(content, headers: true)

        # Convert CSV to readable format
        csv.map do |row|
          row.to_h.map { |k, v| "#{k}: #{v}" }.join("\n")
        end.join("\n\n---\n\n")
      end

      def process_text
        @document.file.download
      end
    end
  end
end
```

### 3.3 Notion Sync Service

`app/services/ai_agent/integrations/notion_sync_service.rb`

```ruby
module AiAgent
  module Integrations
    class NotionSyncService
      def initialize(notion_connection, ai_assistant)
        @connection = notion_connection
        @ai_assistant = ai_assistant
        @client = Notion::Client.new(token: @connection.access_token)
      end

      def sync_pages(page_ids = nil)
        pages_to_sync = page_ids || fetch_all_pages

        pages_to_sync.each do |page_id|
          sync_page(page_id)
        end

        @connection.update!(last_synced_at: Time.current)
      end

      def sync_page(page_id)
        page = @client.page(page_id: page_id)
        blocks = fetch_all_blocks(page_id)
        content = blocks_to_text(blocks)
        title = extract_title(page)

        document = @ai_assistant.ai_documents.find_or_initialize_by(
          source_type: :notion,
          source_url: "notion://#{page_id}"
        )

        document.update!(
          title: title,
          content: content,
          status: :available,
          metadata: { notion_page_id: page_id, last_edited: page.last_edited_time }
        )

        # Regenerate embeddings
        document.ai_embeddings.destroy_all
        EmbeddingService.new(@ai_assistant).create_embeddings_for_document(document)
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

      def fetch_all_blocks(page_id, cursor: nil)
        blocks = []

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
          when 'quote'
            "> #{extract_rich_text(block.dig(:quote, :rich_text))}"
          end
        end.join("\n\n")
      end

      def extract_rich_text(rich_text)
        return '' unless rich_text

        rich_text.map { |t| t[:plain_text] }.join
      end

      def extract_title(page)
        title_prop = page.properties.find { |_, v| v.type == 'title' }&.last
        return 'Untitled' unless title_prop

        title_prop.title.map { |t| t[:plain_text] }.join
      end
    end
  end
end
```

### 3.4 Background Jobs

`app/jobs/ai_documents/process_job.rb`

```ruby
module AiDocuments
  class ProcessJob < ApplicationJob
    queue_as :default

    def perform(document_id)
      document = AiDocument.find(document_id)

      case document.source_type
      when 'website'
        AiAgent::Crawlers::WebsiteCrawler.new(document).crawl
      when 'file'
        AiAgent::Processors::FileProcessor.new(document).process
      when 'notion'
        connection = document.account.ai_notion_connections.first
        AiAgent::Integrations::NotionSyncService.new(connection, document.ai_assistant).sync_page(document.source_url)
      end
    end
  end
end
```

---

## Phase 4: AI Agent Core

### 4.1 Chat Service

`app/services/ai_agent/chat_service.rb`

```ruby
module AiAgent
  class ChatService
    def initialize(conversation)
      @conversation = conversation
      @assistant = conversation.inbox.ai_assistant
      @context_service = VectorSearchService.new(@assistant)
    end

    def generate_response(user_message)
      return nil unless @assistant

      # Build context from knowledge base
      knowledge_context = @context_service.build_context(user_message)

      # Get conversation history
      history = build_message_history

      # Create chat with tools
      chat = RubyLLM.chat(model: @assistant.model)
                    .with_instructions(build_system_prompt(knowledge_context))
                    .with_tools(*available_tools)

      # Add history
      history.each do |msg|
        chat.add_message(role: msg[:role], content: msg[:content])
      end

      # Generate response
      response = chat.ask(user_message)

      # Track context
      update_context(user_message, response)

      response.content
    end

    private

    def build_system_prompt(knowledge_context)
      base_prompt = @assistant.system_prompt || default_system_prompt

      <<~PROMPT
        #{base_prompt}

        #{response_guidelines}

        #{guardrails}

        ## Available Knowledge Base Context
        Use the following information to help answer questions. If the information doesn't contain the answer, say so honestly.

        #{knowledge_context}
      PROMPT
    end

    def response_guidelines
      return '' if @assistant.response_guidelines.blank?

      <<~GUIDELINES
        ## Response Guidelines
        #{@assistant.response_guidelines}
      GUIDELINES
    end

    def guardrails
      return '' if @assistant.guardrails.blank?

      <<~GUARDRAILS
        ## Important Boundaries
        #{@assistant.guardrails}
      GUARDRAILS
    end

    def default_system_prompt
      <<~PROMPT
        You are a helpful customer support assistant for #{@assistant.name}.
        Your role is to assist customers with their questions and issues.
        Be friendly, professional, and concise in your responses.
        If you don't know the answer, be honest and offer to connect them with a human agent.
      PROMPT
    end

    def build_message_history
      @conversation.messages
                   .where(private: false)
                   .order(created_at: :asc)
                   .last(10) # Keep context window manageable
                   .map do |msg|
        {
          role: msg.incoming? ? :user : :assistant,
          content: msg.content
        }
      end
    end

    def available_tools
      tools = [
        AiAgent::Tools::FaqLookupTool.new(@assistant),
        AiAgent::Tools::HandoffTool.new(@conversation),
        AiAgent::Tools::AddNoteTool.new(@conversation)
      ]

      # Add custom tools
      @assistant.ai_custom_tools.active.each do |custom_tool|
        tools << AiAgent::Tools::HttpTool.build(custom_tool, @conversation)
      end

      tools
    end

    def update_context(user_message, response)
      context = @conversation.ai_conversation_context ||
                @conversation.build_ai_conversation_context(ai_assistant: @assistant)

      context.message_count += 1
      context.save!
    end
  end
end
```

### 4.2 Response Job

`app/jobs/ai_agent/response_job.rb`

```ruby
module AiAgent
  class ResponseJob < ApplicationJob
    queue_as :default

    def perform(conversation_id, message_id)
      conversation = Conversation.find(conversation_id)
      message = conversation.messages.find(message_id)

      return unless should_respond?(conversation, message)

      # Show typing indicator
      broadcast_typing(conversation)

      # Generate response
      chat_service = ChatService.new(conversation)
      response_content = chat_service.generate_response(message.content)

      return if response_content.blank?

      # Create response message
      create_response_message(conversation, response_content)
    end

    private

    def should_respond?(conversation, message)
      return false unless message.incoming?
      return false if conversation.resolved? || conversation.snoozed?
      return false unless conversation.inbox.ai_assistant&.active?

      true
    end

    def broadcast_typing(conversation)
      ActionCable.server.broadcast(
        "conversation:#{conversation.account_id}:#{conversation.id}",
        { event: 'typing', user: { name: 'AI Assistant' } }
      )
    end

    def create_response_message(conversation, content)
      conversation.messages.create!(
        message_type: :outgoing,
        content: content,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        sender: ai_sender(conversation)
      )
    end

    def ai_sender(conversation)
      # Use the AI assistant as sender or create a virtual agent bot
      conversation.inbox.ai_assistant
    end
  end
end
```

---

## Phase 5: Tools System

### 5.1 Base Tool Class

`app/lib/ai_agent/tools/base_tool.rb`

```ruby
module AiAgent
  module Tools
    class BaseTool < RubyLLM::Tool
      def initialize(context = nil)
        @context = context
        super()
      end
    end
  end
end
```

### 5.2 FAQ Lookup Tool

`app/lib/ai_agent/tools/faq_lookup_tool.rb`

```ruby
module AiAgent
  module Tools
    class FaqLookupTool < BaseTool
      description "Search the knowledge base for relevant information to answer customer questions"

      params do
        string :query, description: "The search query to find relevant FAQ or documentation"
      end

      def initialize(assistant)
        @assistant = assistant
        super()
      end

      def execute(query:)
        search_service = VectorSearchService.new(@assistant)
        results = search_service.search(query, limit: 5)

        if results.empty?
          { found: false, message: "No relevant information found in the knowledge base" }
        else
          formatted_results = results.map do |r|
            {
              content: r[:content],
              source: r[:source],
              similarity: r[:similarity].round(2)
            }
          end

          { found: true, results: formatted_results }
        end
      end
    end
  end
end
```

### 5.3 Handoff Tool

`app/lib/ai_agent/tools/handoff_tool.rb`

```ruby
module AiAgent
  module Tools
    class HandoffTool < BaseTool
      description "Transfer the conversation to a human agent when the AI cannot help or the customer requests human support"

      params do
        string :reason, description: "The reason for transferring to a human agent"
      end

      def initialize(conversation)
        @conversation = conversation
        super()
      end

      def execute(reason:)
        # Create internal note with reason
        @conversation.messages.create!(
          message_type: :activity,
          content: "AI handoff: #{reason}",
          private: true,
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id
        )

        # Update conversation status
        @conversation.update!(status: :open, assignee: nil)

        # Dispatch event for assignment
        Rails.configuration.dispatcher.dispatch(
          'conversation.bot_handoff',
          Time.zone.now,
          conversation: @conversation,
          reason: reason
        )

        { success: true, message: "Conversation transferred to human support" }
      end
    end
  end
end
```

### 5.4 Add Note Tool

`app/lib/ai_agent/tools/add_note_tool.rb`

```ruby
module AiAgent
  module Tools
    class AddNoteTool < BaseTool
      description "Add a private internal note to the conversation that only agents can see"

      params do
        string :note, description: "The content of the private note"
      end

      def initialize(conversation)
        @conversation = conversation
        super()
      end

      def execute(note:)
        @conversation.messages.create!(
          message_type: :outgoing,
          content: note,
          private: true,
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id
        )

        { success: true, message: "Note added successfully" }
      end
    end
  end
end
```

### 5.5 Custom HTTP Tool Builder

`app/lib/ai_agent/tools/http_tool.rb`

```ruby
module AiAgent
  module Tools
    class HttpTool
      def self.build(custom_tool, conversation)
        tool_class = Class.new(BaseTool) do
          define_singleton_method(:description) { custom_tool.description }

          define_singleton_method(:params) do
            custom_tool.parameters_schema
          end

          define_method(:initialize) do |tool, conv|
            @tool = tool
            @conversation = conv
            super()
          end

          define_method(:execute) do |**params|
            execute_request(params)
          end

          define_method(:execute_request) do |params|
            uri = URI.parse(@tool.endpoint_url)

            request = case @tool.http_method.upcase
                      when 'GET'
                        uri.query = URI.encode_www_form(params)
                        Net::HTTP::Get.new(uri)
                      when 'POST'
                        req = Net::HTTP::Post.new(uri)
                        req.body = render_template(@tool.request_template, params)
                        req.content_type = 'application/json'
                        req
                      end

            # Add auth headers
            add_auth_headers(request)

            # Execute request
            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
              http.request(request)
            end

            # Parse and return response
            parse_response(response)
          end

          define_method(:add_auth_headers) do |request|
            case @tool.auth_type
            when 'bearer'
              request['Authorization'] = "Bearer #{@tool.auth_credentials}"
            when 'basic'
              request.basic_auth(*@tool.auth_credentials.split(':'))
            when 'api_key'
              request['X-API-Key'] = @tool.auth_credentials
            end
          end

          define_method(:render_template) do |template, params|
            return params.to_json if template.blank?

            Liquid::Template.parse(template).render(params.stringify_keys)
          end

          define_method(:parse_response) do |response|
            if response.is_a?(Net::HTTPSuccess)
              JSON.parse(response.body)
            else
              { error: "Request failed with status #{response.code}" }
            end
          rescue JSON::ParserError
            { response: response.body }
          end
        end

        tool_class.new(custom_tool, conversation)
      end
    end
  end
end
```

---

## Phase 6: Conversation Integration

### 6.1 Message Listener

`app/listeners/ai_agent_listener.rb`

```ruby
class AiAgentListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    return unless should_trigger_ai?(message, conversation)

    AiAgent::ResponseJob.perform_later(conversation.id, message.id)
  end

  def conversation_resolved(event)
    conversation = event.data[:conversation]
    assistant = conversation.inbox.ai_assistant

    return unless assistant&.effective_config&.dig('feature_faq')

    # Generate FAQ from resolved conversation
    AiAgent::FaqGeneratorJob.perform_later(conversation.id)
  end

  private

  def should_trigger_ai?(message, conversation)
    return false unless message.incoming?
    return false if conversation.resolved? || conversation.snoozed?
    return false unless conversation.inbox.ai_assistant&.active?
    return false if conversation.assignee.present? && !conversation.assignee.is_a?(AiAssistant)

    true
  end
end
```

### 6.2 Register Listener

Add to `config/initializers/listeners.rb`:

```ruby
Rails.application.config.dispatcher.register_listener(AiAgentListener)
```

### 6.3 Inbox Extension

`app/models/concerns/ai_assistant_inbox_concern.rb`

```ruby
module AiAssistantInboxConcern
  extend ActiveSupport::Concern

  included do
    has_one :ai_assistant_inbox, dependent: :destroy
    has_one :ai_assistant, through: :ai_assistant_inbox
  end

  def ai_enabled?
    ai_assistant&.active?
  end
end
```

Add to `app/models/inbox.rb`:

```ruby
include AiAssistantInboxConcern
```

---

## Phase 7: Frontend & Management UI

### 7.1 Routes

Add to `config/routes.rb`:

```ruby
namespace :api do
  namespace :v1 do
    namespace :accounts do
      resources :ai_assistants do
        resources :documents, controller: 'ai_assistants/documents'
        resources :embeddings, controller: 'ai_assistants/embeddings', only: [:index, :create, :destroy]
        resources :custom_tools, controller: 'ai_assistants/custom_tools'
        member do
          post :playground
        end
      end
      resources :ai_notion_connections, only: [:index, :create, :destroy] do
        member do
          post :sync
        end
      end
    end
  end
end
```

### 7.2 Controllers

`app/controllers/api/v1/accounts/ai_assistants_controller.rb`

```ruby
class Api::V1::Accounts::AiAssistantsController < Api::V1::Accounts::BaseController
  before_action :set_assistant, only: [:show, :update, :destroy, :playground]

  def index
    @assistants = Current.account.ai_assistants
    render json: @assistants
  end

  def show
    render json: @assistant
  end

  def create
    @assistant = Current.account.ai_assistants.new(assistant_params)

    if @assistant.save
      render json: @assistant, status: :created
    else
      render json: { errors: @assistant.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @assistant.update(assistant_params)
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
    response = AiAgent::ChatService.new(nil, @assistant).test_response(params[:message])
    render json: { response: response }
  end

  private

  def set_assistant
    @assistant = Current.account.ai_assistants.find(params[:id])
  end

  def assistant_params
    params.require(:ai_assistant).permit(
      :name, :description, :system_prompt, :response_guidelines, :guardrails, :active,
      config: [:model, :temperature, :max_tokens, :feature_faq, :feature_memory]
    )
  end
end
```

### 7.3 Frontend Components (Vue.js)

Create the following Vue components in `app/javascript/dashboard/routes/dashboard/settings/aiAssistants/`:

1. **Index.vue** - List all AI assistants
2. **Edit.vue** - Create/edit assistant settings
3. **Documents.vue** - Manage knowledge base documents
4. **Playground.vue** - Test assistant responses
5. **CustomTools.vue** - Manage custom tools
6. **NotionConnection.vue** - Notion OAuth and sync

### 7.4 Navigation

Add AI Assistants to settings sidebar in `app/javascript/dashboard/routes/dashboard/settings/settings.routes.js`

---

## Phase 8: Advanced Features

### 8.1 Auto FAQ Generation

`app/services/ai_agent/faq_generator_service.rb`

```ruby
module AiAgent
  class FaqGeneratorService
    def initialize(conversation)
      @conversation = conversation
      @assistant = conversation.inbox.ai_assistant
    end

    def generate
      return unless @assistant
      return unless has_meaningful_exchange?

      # Build prompt for FAQ extraction
      messages = @conversation.messages.where(private: false).order(:created_at)
      transcript = messages.map { |m| "#{m.sender_type}: #{m.content}" }.join("\n")

      chat = RubyLLM.chat(model: 'gpt-4o-mini')
                    .with_instructions(faq_generation_prompt)

      response = chat.ask("Generate FAQ from this conversation:\n\n#{transcript}")

      # Parse and save FAQs
      faqs = JSON.parse(response.content)
      save_faqs(faqs)
    end

    private

    def has_meaningful_exchange?
      incoming = @conversation.messages.where(message_type: :incoming).count
      outgoing = @conversation.messages.where(message_type: :outgoing).count
      incoming >= 1 && outgoing >= 1
    end

    def faq_generation_prompt
      <<~PROMPT
        Analyze the conversation and extract FAQ entries.
        Return a JSON array with objects containing "question" and "answer" keys.
        Only extract clear, complete Q&A pairs that would be useful for other customers.
        If no clear FAQ can be extracted, return an empty array.
      PROMPT
    end

    def save_faqs(faqs)
      faqs.each do |faq|
        next if duplicate?(faq['question'])

        embedding = EmbeddingService.new(@assistant).generate_embedding(faq['question'])

        @assistant.ai_embeddings.create!(
          question: faq['question'],
          content: faq['answer'],
          embedding: embedding,
          status: :pending,
          metadata: { source: 'conversation', conversation_id: @conversation.id }
        )
      end
    end

    def duplicate?(question)
      embedding = EmbeddingService.new(@assistant).generate_embedding(question)
      similar = @assistant.ai_embeddings.semantic_search(embedding, limit: 1).first

      similar && similar.neighbor_distance < 0.3
    end
  end
end
```

### 8.2 Contact Memory

`app/services/ai_agent/contact_memory_service.rb`

```ruby
module AiAgent
  class ContactMemoryService
    def initialize(contact)
      @contact = contact
    end

    def build_context
      notes = @contact.notes.order(created_at: :desc).limit(5)
      conversations_summary = recent_conversations_summary

      {
        contact_name: @contact.name,
        contact_email: @contact.email,
        custom_attributes: @contact.custom_attributes,
        recent_notes: notes.map(&:content),
        conversation_history: conversations_summary
      }
    end

    def add_insight(conversation)
      return unless should_generate_insight?(conversation)

      insight = generate_insight(conversation)
      return if insight.blank?

      @contact.notes.create!(
        content: "[AI Generated] #{insight}",
        account_id: @contact.account_id
      )
    end

    private

    def recent_conversations_summary
      @contact.conversations.order(created_at: :desc).limit(3).map do |conv|
        {
          id: conv.display_id,
          status: conv.status,
          labels: conv.labels.pluck(:title),
          message_count: conv.messages.count
        }
      end
    end

    def should_generate_insight?(conversation)
      conversation.resolved? && conversation.messages.count >= 3
    end

    def generate_insight(conversation)
      transcript = conversation.messages.where(private: false)
                              .order(:created_at)
                              .map { |m| "#{m.sender_type}: #{m.content}" }
                              .join("\n")

      chat = RubyLLM.chat(model: 'gpt-4o-mini')
      response = chat.ask(<<~PROMPT)
        Summarize key insights about this customer from the conversation.
        Focus on: preferences, issues, satisfaction, notable details.
        Keep it under 100 words.

        Conversation:
        #{transcript}
      PROMPT

      response.content
    end
  end
end
```

### 8.3 Multi-language Support

`app/services/ai_agent/language_detector_service.rb`

```ruby
module AiAgent
  class LanguageDetectorService
    def detect(text)
      return 'en' if text.blank?

      chat = RubyLLM.chat(model: 'gpt-4o-mini')
      response = chat.ask(<<~PROMPT)
        Detect the language of this text and return only the ISO 639-1 code (e.g., "en", "es", "fr").
        Text: #{text.truncate(500)}
      PROMPT

      response.content.strip.downcase
    end
  end
end
```

---

## Configuration

### Environment Variables

```bash
# LLM Configuration
OPENAI_API_KEY=your_openai_api_key
AI_DEFAULT_MODEL=gpt-4o
AI_EMBEDDING_MODEL=text-embedding-3-small

# Notion Integration
NOTION_CLIENT_ID=your_notion_client_id
NOTION_CLIENT_SECRET=your_notion_client_secret
NOTION_REDIRECT_URI=https://your-app.com/oauth/notion/callback
```

### Installation Config

Add to `config/installation_config.yml`:

```yaml
ai_agent:
  enabled: true
  default_model: gpt-4o
  embedding_model: text-embedding-3-small
  max_documents_per_assistant: 50
  max_embeddings_per_document: 1000
```

---

## Testing

### Test Files to Create

```
spec/
├── models/
│   ├── ai_assistant_spec.rb
│   ├── ai_document_spec.rb
│   ├── ai_embedding_spec.rb
│   └── ai_custom_tool_spec.rb
├── services/
│   └── ai_agent/
│       ├── embedding_service_spec.rb
│       ├── vector_search_service_spec.rb
│       ├── chat_service_spec.rb
│       └── crawlers/
│           └── website_crawler_spec.rb
├── jobs/
│   └── ai_agent/
│       └── response_job_spec.rb
└── lib/
    └── ai_agent/
        └── tools/
            ├── faq_lookup_tool_spec.rb
            └── handoff_tool_spec.rb
```

---

## Implementation Order

1. **Week 1-2**: Phase 1 (Database & Models)
2. **Week 2-3**: Phase 2 (Embeddings & Vector Search)
3. **Week 3-4**: Phase 3 (Onboarding - Website, Files)
4. **Week 4-5**: Phase 4 (AI Agent Core)
5. **Week 5-6**: Phase 5 (Tools System)
6. **Week 6-7**: Phase 6 (Conversation Integration)
7. **Week 7-8**: Phase 7 (Frontend UI)
8. **Week 8-9**: Phase 8 (Advanced Features)
9. **Week 9-10**: Testing & Polish

---

## Security Considerations

1. **API Key Storage**: Use Rails encrypted credentials for LLM API keys
2. **Rate Limiting**: Implement rate limiting for AI responses
3. **Content Filtering**: Add guardrails for inappropriate content
4. **Data Privacy**: Ensure embeddings don't leak PII across accounts
5. **Tool Execution**: Validate and sanitize all tool parameters
6. **OAuth Tokens**: Use encrypted storage for Notion tokens

---

## Monitoring & Observability

1. **Usage Tracking**: Track AI response counts per account
2. **Latency Monitoring**: Monitor response generation times
3. **Error Tracking**: Log and alert on AI failures
4. **Cost Tracking**: Monitor token usage for billing
5. **Quality Metrics**: Track handoff rates and customer satisfaction

---

## Future Enhancements

1. **Multi-Agent Scenarios**: Support for specialized sub-agents
2. **Voice Support**: Audio message transcription and TTS responses
3. **Image Understanding**: Process images in conversations
4. **Proactive Outreach**: AI-initiated follow-ups
5. **A/B Testing**: Test different prompts and configurations
6. **Fine-tuning**: Support for custom fine-tuned models

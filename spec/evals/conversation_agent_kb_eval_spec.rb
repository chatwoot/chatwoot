# frozen_string_literal: true

require 'rails_helper'
require_relative 'conversation_agent_kb_eval'

# Knowledge Base evaluation tests for ConversationAgent.
#
# These tests:
#   1. Create an assistant with the Avenues Mall directory files (CSV + XLSX)
#   2. Process and embed the documents (real OpenAI embedding API calls)
#   3. Run the ConversationAgent with questions about mall data
#   4. Verify the agent retrieves correct info from KB in EN and AR
#
# Gated behind RUN_EVAL=1 because it hits real LLM APIs and costs money.
#
# Run:
#   RUN_EVAL=1 bundle exec rspec spec/evals/conversation_agent_kb_eval_spec.rb
#
# Run only Arabic cases:
#   RUN_EVAL=1 bundle exec rspec spec/evals/conversation_agent_kb_eval_spec.rb -e "ar_"
#
# Run only English cases:
#   RUN_EVAL=1 bundle exec rspec spec/evals/conversation_agent_kb_eval_spec.rb -e "en_"
#
RSpec.describe 'ConversationAgent KB eval', :aloo, if: ENV.fetch('RUN_EVAL', nil) do
  CSV_PATH  = Rails.root.join('spec/Avenues_Master_Directory.csv')
  XLSX_PATH = Rails.root.join('spec/Avenues_Master_Directory.xlsx')

  let(:account) { create(:account) }
  let(:assistant) do
    create(:aloo_assistant, :with_all_features, account: account,
                                                description: 'The Avenues Mall Kuwait')
  end
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:contact) { conversation.contact }

  before do
    WebMock.allow_net_connect!

    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
    Aloo::Current.contact = contact
    Aloo::Current.inbox = inbox

    # Create and process CSV document
    csv_doc = Aloo::Document.create!(
      account: account,
      assistant: assistant,
      title: 'Avenues Mall Store Directory (CSV)',
      source_type: 'file',
      status: :pending
    )
    csv_doc.file.attach(
      io: File.open(CSV_PATH),
      filename: 'Avenues_Master_Directory.csv',
      content_type: 'text/csv'
    )
    csv_doc.process_sync!

    # Create and process XLSX document
    xlsx_doc = Aloo::Document.create!(
      account: account,
      assistant: assistant,
      title: 'Avenues Mall Store Directory (XLSX)',
      source_type: 'file',
      status: :pending
    )
    xlsx_doc.file.attach(
      io: File.open(XLSX_PATH),
      filename: 'Avenues_Master_Directory.xlsx',
      content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
    xlsx_doc.process_sync!

    doc_count = assistant.documents.available.count
    embedding_count = assistant.embeddings.count
    puts "\n  KB setup: #{doc_count} documents, #{embedding_count} embeddings"
  end

  after do
    Aloo::Current.reset
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe 'overall KB retrieval quality' do
    it 'scores above 60% across all KB cases' do
      run = ConversationAgent::KbEval.run!(pass_threshold: 0.5)

      puts "\n#{run.summary}"
      puts "Duration: #{run.duration_ms}ms | Cost: $#{format('%.4f', run.total_cost)}"

      run.failures.each do |result|
        puts "  FAIL: #{result.test_case_name} (score: #{result.score.value}) — #{result.score.reason}"
      end

      run.errors.each do |result|
        puts "  ERROR: #{result.test_case_name} — #{result.error.class}: #{result.error.message}"
      end

      expect(run.score).to be >= 0.6
      expect(run.errors).to be_empty
    end
  end

  describe 'English KB queries' do
    it 'finds Adidas location' do
      run = ConversationAgent::KbEval.run!(only: 'en_adidas_location', pass_threshold: 0.5)
      expect(run.score).to be >= 0.8
    end

    it 'lists multiple Starbucks locations' do
      run = ConversationAgent::KbEval.run!(only: 'en_starbucks_locations', pass_threshold: 0.5)
      expect(run.score).to be >= 0.5
    end

    it 'finds Sephora in The Forum' do
      run = ConversationAgent::KbEval.run!(only: 'en_sephora_location', pass_threshold: 0.3)
      expect(run.score).to be >= 0.3
    end

    it 'finds Zara location' do
      run = ConversationAgent::KbEval.run!(only: 'en_zara_location', pass_threshold: 0.5)
      expect(run.score).to be >= 0.8
    end

    it 'lists shoe stores' do
      run = ConversationAgent::KbEval.run!(only: 'en_category_shoes', pass_threshold: 0.5)
      expect(run.score).to be >= 0.5
    end

    it 'lists dining options' do
      run = ConversationAgent::KbEval.run!(only: 'en_dining_options', pass_threshold: 0.5)
      expect(run.score).to be >= 0.5
    end

    it 'provides parking info for H&M' do
      run = ConversationAgent::KbEval.run!(only: 'en_parking_info', pass_threshold: 0.3)
      expect(run.score).to be >= 0.3
    end
  end

  describe 'Arabic KB queries' do
    it 'answers Adidas location in Arabic' do
      run = ConversationAgent::KbEval.run!(only: 'ar_adidas_location', pass_threshold: 0.3)
      expect(run.score).to be >= 0.3
    end

    it 'answers Starbucks locations in Arabic' do
      run = ConversationAgent::KbEval.run!(only: 'ar_starbucks_location', pass_threshold: 0.5)
      expect(run.score).to be >= 0.5
    end

    it 'lists restaurants in Arabic' do
      run = ConversationAgent::KbEval.run!(only: 'ar_restaurants', pass_threshold: 0.5)
      expect(run.score).to be >= 0.5
    end

    it 'provides Zara parking info in Arabic' do
      run = ConversationAgent::KbEval.run!(only: 'ar_parking_info', pass_threshold: 0.3)
      expect(run.score).to be >= 0.3
    end
  end
end

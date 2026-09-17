require 'spec_helper'
require 'securerandom'
require_relative '../../../lib/wootql'

# These models deliberately avoid the Rails app and its database connections.
class WootQLSpecRecord < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
  self.abstract_class = true
end

class WootQLSpecMessage < WootQLSpecRecord
end

class WootQLSpecConversation < WootQLSpecRecord
  enum :status, { open: 0, resolved: 1 }
end

# Opt-in, real PostgreSQL checks. Use a disposable database, never an application
# database. Each example creates its own schema and rolls it back afterwards.
RSpec.describe 'WootQL PostgreSQL execution' do
  before(:context) do
    skip 'Set WOOTQL_TEST_DATABASE_URL to a disposable PostgreSQL database' unless ENV['WOOTQL_TEST_DATABASE_URL']

    WootQLSpecRecord.establish_connection(ENV.fetch('WOOTQL_TEST_DATABASE_URL'))
  end

  after(:context) do
    WootQLSpecRecord.remove_connection if ENV['WOOTQL_TEST_DATABASE_URL']
  end

  around do |example|
    WootQLSpecRecord.transaction do
      connection = WootQLSpecRecord.connection
      namespace = "wootql_spec_#{SecureRandom.hex(8)}"
      connection.execute("CREATE SCHEMA #{connection.quote_column_name(namespace)}")
      connection.create_table("#{namespace}.conversations") do |table|
        table.integer :account_id, null: false
        table.integer :status, null: false, default: 0
        table.datetime :last_activity_at
      end
      connection.create_table("#{namespace}.messages") do |table|
        table.integer :account_id, null: false
        table.bigint :conversation_id
        table.text :content
        table.boolean :private, default: false
        table.datetime :created_at
        table.datetime :updated_at
      end
      WootQLSpecMessage.table_name = "#{namespace}.messages"
      WootQLSpecConversation.table_name = "#{namespace}.conversations"
      WootQLSpecMessage.reset_column_information
      WootQLSpecConversation.reset_column_information
      example.run
      raise ActiveRecord::Rollback
    end
  end

  let(:now) { Time.utc(2026, 9, 17, 12) }
  let(:data) { double('authorized test scopes') }
  let(:catalog) do
    {
      'messages' => { fields: %w[id conversation_id content private created_at updated_at],
                      relations: { 'conversation' => ['conversations', 'conversation_id', :one] } },
      'conversations' => { fields: %w[id status last_activity_at], relations: {} }
    }
  end
  let(:schema) { Wootql::Schema.new }
  let(:query) { Wootql::Query.new(data: data, database: WootQLSpecRecord, clock: -> { now }) }

  before do
    stub_const('Captain::Apropos::ResourceCatalog', double('Chatwoot resource catalog', entries: catalog))
    allow(Captain::Apropos::ResourceCatalog).to receive(:fetch) { |resource| catalog.fetch(resource) }
    allow(data).to receive(:scope).with('messages').and_return(WootQLSpecMessage.where(account_id: 7))
    allow(data).to receive(:scope).with('conversations').and_return(WootQLSpecConversation.where(account_id: 7))
  end

  it 'returns only the literal match for a SQL-looking bound parameter' do
    payload = "'; DELETE FROM messages; --"
    target = WootQLSpecMessage.create!(account_id: 7, content: payload)
    WootQLSpecMessage.create!(account_id: 7, content: 'not a match')
    WootQLSpecMessage.create!(account_id: 8, content: payload)
    result = query.run('messages | where content = $text | return id', { 'text' => payload })
    expect(result['items']).to eq([{ 'id' => target.id }])
    expect(WootQLSpecMessage.count).to eq(3)
  end

  it 'executes bound collection membership and empty selections correctly' do
    first = WootQLSpecMessage.create!(account_id: 7)
    second = WootQLSpecMessage.create!(account_id: 7)
    outsider = WootQLSpecMessage.create!(account_id: 8)
    source = 'messages | where id in $ids | return id'
    expect(query.run(source, { 'ids' => [first.id, outsider.id] })['items']).to eq([{ 'id' => first.id }])
    expect(query.run(source, { 'ids' => [] })['items']).to eq([])
    expect(WootQLSpecMessage.exists?(second.id)).to be(true)
  end

  it 'compares joined timestamp fields without admitting records from another account' do
    conversation = WootQLSpecConversation.create!(account_id: 7, last_activity_at: now)
    foreign_conversation = WootQLSpecConversation.create!(account_id: 8, last_activity_at: now)
    matching = WootQLSpecMessage.create!(account_id: 7, conversation_id: conversation.id, created_at: now + 1)
    WootQLSpecMessage.create!(account_id: 7, conversation_id: conversation.id, created_at: now - 1)
    WootQLSpecMessage.create!(account_id: 7, conversation_id: foreign_conversation.id, created_at: now + 1)
    result = query.run('messages | where created_at > conversation.last_activity_at | return id')
    expect(result['items']).to eq([{ 'id' => matching.id }])
  end

  it 'keeps account boundaries even when user predicates match every row' do
    ours = WootQLSpecMessage.create!(account_id: 7)
    WootQLSpecMessage.create!(account_id: 8)
    expect(query.run('messages | where id = 1 or id != 1 | return id')['items']).to eq([{ 'id' => ours.id }])
  end

  it 'paginates a stable dataset without losing or duplicating rows' do
    WootQLSpecMessage.insert_all!(Array.new(205) { { account_id: 7, created_at: now } })
    prepared = query.prepare('messages | where created_at <= now() | return id | sort id asc')
    first = prepared.page
    second = prepared.page(first.fetch('next_offset'))
    ids = (first['items'] + second['items']).map { |row| row['id'] }
    expect(ids).to eq(WootQLSpecMessage.order(:id).pluck(:id))
    expect(ids.uniq.size).to eq(205)
    expect(second['next_offset']).to be(false)
  end

  it 'preserves take-before-filter semantics and enum binding' do
    WootQLSpecConversation.create!(account_id: 7, status: :resolved)
    target = WootQLSpecConversation.create!(account_id: 7, status: :open)
    expect(query.run('conversations | take 1 | where status = "open"')['items']).to eq([])
    expect(query.run('conversations | where status = "open" | take 1 | return id')['items']).to eq([{ 'id' => target.id }])
  end

  it 'enables read-only mode during a query and restores the outer transaction settings' do
    WootQLSpecMessage.create!(account_id: 7)
    catalog['messages'][:query_fields] = { 'read_only' => :string }
    allow(schema).to receive(:expression).with('messages', 'read_only').and_return("current_setting('transaction_read_only')")
    allow(Wootql::Schema).to receive(:new).and_return(schema)
    protected_query = Wootql::Query.new(data: data, database: WootQLSpecRecord)
    connection = WootQLSpecRecord.connection
    before_timeout = connection.select_value('SHOW statement_timeout')
    expect(connection.select_value('SHOW transaction_read_only')).to eq('off')
    expect(protected_query.run('messages | return read_only')['items']).to eq([{ 'read_only' => 'on' }])
    expect(connection.select_value('SHOW transaction_read_only')).to eq('off')
    expect(connection.select_value('SHOW statement_timeout')).to eq(before_timeout)
    expect { WootQLSpecMessage.create!(account_id: 7) }.to change(WootQLSpecMessage, :count).by(1)
  end
end

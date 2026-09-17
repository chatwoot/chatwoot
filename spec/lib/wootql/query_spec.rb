require 'spec_helper'
require_relative 'query_context'

RSpec.describe Wootql::Query do
  subject(:query) { described_class.new(data: data, database: database, budget: budget, clock: clock) }

  include_context 'with a WootQL catalog'

  let(:database) { double('database pool') }
  let(:budget) { { queries: 0 } }
  let(:clock) { -> { now } }
  let(:result) { ActiveRecord::Result.new(['id'], Array.new(201) { |index| [index + 1] }) }

  before do
    allow(database).to receive(:with_connection).and_yield(connection)
    allow(connection).to receive(:execute).with('SET LOCAL statement_timeout = 5000')
    allow(connection).to receive(:execute).with('SET LOCAL transaction_read_only = on')
    allow(connection).to receive(:select_all).and_return(result)
    allow(connection).to receive(:transaction) do |**_options, &work|
      work.call
    rescue ActiveRecord::Rollback
      nil
    end
  end

  it 'returns a bounded page with a continuation offset, not a claim of total coverage' do
    page = query.run('messages | return id')
    expect(page['items'].size).to eq(200)
    expect(page['items'].first).to eq('id' => 1)
    expect(page['next_offset']).to eq(200)
    expect(budget[:queries]).to eq(1)
  end

  it 'marks the final page when there is no extra row' do
    allow(connection).to receive(:select_all).and_return(ActiveRecord::Result.new(['id'], [[1]]))
    expect(query.run('messages')['next_offset']).to be(false)
  end

  it 'does not execute SQL when preparing a reusable query' do
    expect(connection).not_to receive(:select_all)
    expect(query.prepare('messages')).to be_a(Wootql::PreparedQuery)
    expect(budget[:queries]).to eq(0)
  end

  it 'freezes relative time boundaries for every page of one prepared query' do
    ticks = [now, now + 60]
    allow(clock).to receive(:call) { ticks.shift }
    prepared = query.prepare('messages | where created_at >= now() - 7d | return id')
    first_page = prepared.page(0, debug: true)
    second_page = prepared.page(200, debug: true)
    expect(first_page['binds']).to eq([now - (7 * 86_400)])
    expect(second_page['binds']).to eq(first_page['binds'])
    expect(second_page['sql']).to end_with('LIMIT 201 OFFSET 200')
    expect(clock).to have_received(:call).once
    expect(budget[:queries]).to eq(2)
  end

  it 'captures a fresh clock value for a separately prepared query' do
    allow(clock).to receive(:call).and_return(now, now + 60)
    first_page = query.prepare('messages | where created_at < now()').page(0, debug: true)
    second_page = query.prepare('messages | where created_at < now()').page(0, debug: true)
    expect(second_page['binds']).to eq([first_page['binds'].first + 60])
  end

  it 'does not allow caller parameter mutations to change later pages' do
    parameters = { 'text' => +'original' }
    prepared = query.prepare('messages | where content = $text', parameters)
    parameters['text'].replace('changed')
    expect(prepared.page(0, debug: true)['binds']).to eq(['original'])
  end

  it 'rejects invalid offsets before executing SQL' do
    expect(connection).not_to receive(:select_all)
    [-1, 100_001, '200', 1.5].each do |offset|
      expect { query.run('messages', {}, offset) }.to raise_error(Wootql::Error, /offset/)
    end
  end

  it 'enforces the shared query budget on prepared pages' do
    budget[:queries] = 99
    prepared = query.prepare('messages')
    prepared.page
    expect { prepared.page(200) }.to raise_error(Wootql::Error, /budget exhausted/)
    expect(connection).to have_received(:select_all).once
  end

  it 'uses a rollback-isolated savepoint for the query timeout' do
    query.run('messages')
    expect(connection).to have_received(:transaction).with(requires_new: true)
    expect(connection).to have_received(:execute).with('SET LOCAL statement_timeout = 5000')
  end

  it 'sets database read-only mode before executing the compiled query' do
    expect(connection).to receive(:execute).with('SET LOCAL transaction_read_only = on').ordered
    expect(connection).to receive(:select_all).ordered.and_return(result)
    query.run('messages')
  end

  it 'does not execute a query if read-only mode cannot be enabled' do
    allow(connection).to receive(:execute).with('SET LOCAL transaction_read_only = on')
                                          .and_raise(ActiveRecord::StatementInvalid, 'read-only setup failed')
    expect(connection).not_to receive(:select_all)
    expect { query.run('messages') }.to raise_error(Wootql::Error, /database execution failed/)
  end

  it 'validates malformed parameter containers at the public boundary' do
    expect { query.run('messages', []) }.to raise_error(Wootql::Error, /parameters/)
    expect { query.run('messages', { id: 1 }) }.to raise_error(Wootql::Error, /string keys/)
  end

  it 'does not expose SQL or bind values unless debug output is requested' do
    expect(query.run('messages').keys).to contain_exactly('items', 'next_offset')
  end

  it 'reports a database failure as an error, never as an empty dataset' do
    allow(connection).to receive(:select_all).and_raise(ActiveRecord::StatementInvalid, 'synthetic failure')
    expect { query.run('messages') }.to raise_error(Wootql::Error, /database execution failed/) { |error|
      expect(error.context.join(' ')).to include('does not establish that the matching dataset is empty')
    }
  end
end

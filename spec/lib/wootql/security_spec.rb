require 'spec_helper'
require_relative 'query_context'

RSpec.describe 'WootQL read-only and injection boundaries' do
  include_context 'with a WootQL catalog'

  let(:database) { double('database pool') }
  let(:query) { Wootql::Query.new(data: data, database: database) }

  [
    'UPDATE messages SET content = "changed"',
    'DELETE FROM messages',
    'INSERT INTO messages VALUES (1)',
    'DROP TABLE messages',
    'TRUNCATE messages',
    'ALTER TABLE messages ADD hacked text',
    'COPY messages TO PROGRAM "anything"',
    'SELECT * FROM messages',
    'messages | update content = "changed"',
    'messages | delete',
    'messages | insert id = 1',
    'messages | where id = 1; DELETE FROM messages',
    'messages | where id = 1 -- comment',
    'messages | where id = 1 /* comment */',
    'messages | where id = 1 UNION SELECT password FROM users',
    'messages | where id in (SELECT id FROM messages)',
    'messages | return pg_sleep(10)',
    'messages | summarize pg_sleep(id)',
    'messages | return id as "id; DROP TABLE messages"',
    'messages | join contacts as "c; DELETE" on id = c.id',
    'messages | where id = 1 or 1 = 1',
    'messages | take 1; COMMIT',
    'messages | where id = 1 | raw "DELETE FROM messages"',
    'pg_catalog.pg_authid',
    'secrets',
    'messages | return password_digest',
    'messages | where private = true | return content) --'
  ].each do |source|
    it "rejects #{source.inspect} before acquiring a query connection" do
      expect(database).not_to receive(:with_connection)
      expect { query.run(source) }.to raise_error(Wootql::Error)
    end
  end

  it 'does not accept caller-authored ASTs or logical plans as source' do
    expect(database).not_to receive(:with_connection)
    expect { query.run({ resource: 'messages', sql: 'DELETE FROM messages' }) }.to raise_error(Wootql::Error, /source/)
  end

  it 'does not interpolate malicious offsets or limits' do
    expect(database).not_to receive(:with_connection)
    expect { query.run('messages', {}, '0; DELETE FROM messages') }.to raise_error(Wootql::Error, /offset/)
    expect { query.run('messages | take $limit', { 'limit' => '1; DELETE FROM messages' }) }.to raise_error(Wootql::Error, /integer/)
  end

  ["'; DELETE FROM messages; --", '" OR 1=1 --', '$$; DROP TABLE contacts; $$', "\\'); SELECT pg_sleep(10); --"].each do |payload|
    it "keeps #{payload.inspect} as a bound scalar or collection value" do
      ['messages | where content = $payload', 'messages | where content in $payloads'].each do |source|
        parameters = { 'payload' => payload, 'payloads' => [payload] }
        plan = Wootql::Resolver.new(data: data, schema: schema, parameters: parameters).resolve(Wootql::Parser.new(source).parse)
        compiler = Wootql::Compiler.new(connection: connection)
        sql = compiler.compile(plan)
        expect(sql).not_to include(payload)
        expect(sql).to include('$1', '"messages"."account_id" = 7')
        expect(compiler.binds.map(&:value_for_database)).to eq([payload])
      end
    end

    it "binds #{payload.inspect} when provided as a quoted WootQL literal" do
      source = "messages | where content = #{JSON.generate(payload)}"
      plan = Wootql::Resolver.new(data: data, schema: schema, parameters: {}).resolve(Wootql::Parser.new(source).parse)
      compiler = Wootql::Compiler.new(connection: connection)
      expect(compiler.compile(plan)).not_to include(payload)
      expect(compiler.binds.first.value_for_database).to eq(payload)
    end
  end

  it 'rejects SQL fragments supplied as integer list members' do
    expect(database).not_to receive(:with_connection)
    expect { query.run('messages | where id in $ids', { 'ids' => ['1) OR TRUE --'] }) }.to raise_error(Wootql::Error, /integer/)
  end

  it 'preserves trusted scopes under disjunction and joins' do
    source = 'messages | join conversations as c on conversation_id = c.id | where id = 1 or id != 1'
    plan = Wootql::Resolver.new(data: data, schema: schema, parameters: {}).resolve(Wootql::Parser.new(source).parse)
    sql = Wootql::Compiler.new(connection: connection).compile(plan)
    expect(sql).to include('"messages"."account_id" = 7', '"conversations"."account_id" = 7')
    expect(sql).to include('WHERE (q."id" =', ' OR q."id" <>')
  end
end

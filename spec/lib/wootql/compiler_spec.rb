require 'spec_helper'
require_relative 'query_context'

RSpec.describe Wootql::Compiler do
  subject(:sql) { compiler.compile(plan) }

  include_context 'with a WootQL catalog'

  let(:source) { 'messages' }
  let(:parameters) { {} }
  let(:plan) { Wootql::Resolver.new(data: data, schema: schema, parameters: parameters, now: now).resolve(Wootql::Parser.new(source).parse) }
  let(:compiler) { described_class.new(connection: connection) }

  context 'with array membership' do
    let(:source) { 'messages | where id in $ids' }
    let(:parameters) { { 'ids' => [3, 7] } }

    it 'binds collection values instead of inserting them into SQL' do
      expect(sql).to include('q."id" IN ($1, $2)')
      expect(compiler.binds.map(&:value_for_database)).to eq([3, 7])
    end

    it 'compiles an empty list as false, not invalid SQL or an omitted filter' do
      parameters['ids'] = []
      expect(sql).to include('WHERE FALSE')
      expect(sql).not_to include('IN ()')
    end
  end

  context 'with field comparisons' do
    let(:source) { 'messages | where created_at > conversation.last_activity_at' }

    it 'compares quoted fields while preserving account scope on both sides' do
      expect(sql).to include('q."created_at" > q."conversation.last_activity_at"')
      expect(sql).to include('"messages"."account_id" = 7', '"conversations"."account_id" = 7', 'LEFT JOIN')
    end
  end

  context 'with untrusted parameter text' do
    let(:source) { 'messages | where content = $text' }
    let(:parameters) { { 'text' => "'; DROP TABLE messages; --" } }

    it 'keeps the entire value in a bind parameter' do
      expect(sql).not_to include('DROP TABLE')
      expect(compiler.binds.first.value_for_database).to eq(parameters['text'])
    end
  end

  context 'with literal contains' do
    let(:source) { 'messages | where content contains $text' }
    let(:parameters) { { 'text' => '50%_off' } }

    it 'escapes SQL wildcard characters' do
      expect(sql).to include('ILIKE $1')
      expect(compiler.binds.first.value_for_database).to eq('%50\\%\\_off%')
    end
  end

  context 'with a left join followed by aggregation' do
    let(:source) { 'conversations | join left messages as m on id = m.conversation_id | summarize count(m.id) as total by id' }

    it 'counts matched messages rather than manufacturing a match for empty conversations' do
      expect(sql).to include('LEFT JOIN', 'COUNT(q."m.id") AS "total"', 'GROUP BY q."id"')
      expect(sql).to include('"conversations"."account_id" = 7', '"messages"."account_id" = 7')
    end
  end

  context 'with label emptiness' do
    let(:source) { 'conversations | where labels is empty' }

    it 'retains the distinction between null and empty lists' do
      expect(sql).to include('CARDINALITY(q."labels") = 0')
      expect(sql).not_to include('COALESCE')
    end
  end

  context 'with take before where' do
    let(:source) { 'messages | take 10 | where private = false' }

    it 'preserves the limit inside the filter input' do
      expect(sql).to match(/LIMIT 10\) q WHERE q\."private" = \$1/)
    end
  end
end

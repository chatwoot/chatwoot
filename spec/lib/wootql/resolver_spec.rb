require 'spec_helper'
require_relative 'query_context'

RSpec.describe Wootql::Resolver do
  subject(:plan) { described_class.new(data: data, schema: schema, parameters: parameters, now: now).resolve(ast) }

  include_context 'with a WootQL catalog'

  let(:parameters) { {} }
  let(:source) { 'messages' }
  let(:ast) { Wootql::Parser.new(source).parse }

  context 'with array membership' do
    let(:source) { 'messages | where conversation_id in $ids' }
    let(:parameters) { { 'ids' => [1, 2, 3] } }

    it 'validates and resolves every collection member' do
      expect(plan.options[:value]).to eq([1, 2, 3])
    end

    it 'represents an empty selection without changing its scope' do
      parameters['ids'] = []
      expect(plan.options[:value]).to eq([])
    end

    [1, '1,2', [[1]], [1, '2'], [nil]].each do |value|
      it "rejects an invalid collection #{value.inspect}" do
        parameters['ids'] = value
        expect { plan }.to raise_error(Wootql::Error)
      end
    end

    it 'reports a missing parameter explicitly' do
      parameters.clear
      expect { plan }.to raise_error(Wootql::Error, /Missing WootQL parameter: \$ids/)
    end
  end

  context 'with scalar membership parameters' do
    let(:source) { 'messages | where id in ($id)' }
    let(:parameters) { { 'id' => [1, 2] } }

    it 'does not silently flatten a collection used in a scalar position' do
      expect { plan }.to raise_error(Wootql::Error, /integer/)
    end
  end

  context 'with field comparisons' do
    let(:source) { 'messages | where created_at > conversation.last_activity_at' }

    it 'resolves the right field and its authorized relationship before filtering' do
      expect(plan.operation).to eq(:filter)
      expect(plan.options[:value]).to eq(field: 'conversation.last_activity_at')
      expect(plan.input.operation).to eq(:join)
      expect(plan.input.options[:kind]).to eq('left')
    end
  end

  [
    'messages | where id = content',
    'messages | where created_at > nonexistent',
    'messages | return id | where created_at > updated_at',
    'messages | where private > private',
    'conversations | where labels = labels',
    'messages | where content contains sender_type'
  ].each do |invalid_source|
    it "rejects incompatible or unsupported field comparisons: #{invalid_source}" do
      query = Wootql::Parser.new(invalid_source).parse
      expect { described_class.new(data: data, schema: schema, parameters: {}, now: now).resolve(query) }.to raise_error(Wootql::Error)
    end
  end

  context 'with bound clock values' do
    let(:source) { 'messages | where created_at >= now() - 7d | where updated_at <= now()' }

    it 'uses one supplied instant for every relative timestamp' do
      expect(plan.options[:value]).to eq(now)
      expect(plan.input.options[:value]).to eq(now - (7 * 86_400))
    end
  end

  [
    'messages | return id as value, content as value',
    'messages | summarize count() as id by id',
    'messages | where id = null',
    'messages | where id is empty',
    'conversations | where status = "invented"',
    'conversations | return messages.content',
    'messages | take -1',
    'messages | take 100001'
  ].each do |invalid_source|
    it "retains validation for #{invalid_source}" do
      query = Wootql::Parser.new(invalid_source).parse
      expect { described_class.new(data: data, schema: schema, parameters: {}, now: now).resolve(query) }.to raise_error(Wootql::Error)
    end
  end

  it 'reports current fields when a projection removed a requested field' do
    query = Wootql::Parser.new('messages | return id | sort created_at').parse
    expect { described_class.new(data: data, schema: schema, parameters: {}, now: now).resolve(query) }.to raise_error(Wootql::Error) { |error|
      expect(error.evidence.join(' ')).to include('1 total', 'id: integer')
    }
  end
end

require 'spec_helper'
require_relative '../../../lib/wootql'

RSpec.describe Wootql::Parser do
  it 'preserves stage ordering and the existing pipe syntax' do
    query = described_class.new('conversations | take 10 | where status = "open" | return id | sort id desc').parse
    expect(query.resource).to eq('conversations')
    expect(query.stages.map { |stage| stage[:operation] }).to eq(%w[take where return sort])
  end

  it 'accepts a named collection parameter for membership' do
    predicate = described_class.new('messages | where conversation_id in $ids').parse.stages.first[:arguments]
    expect(predicate).to eq(operator: 'in', field: 'conversation_id', value: { parameter: 'ids' })
  end

  it 'uses return for field selection and renaming' do
    stage = described_class.new('messages | return id, content as message').parse.stages.first
    expect(stage).to eq(operation: 'return', arguments: [{ field: 'id', name: 'id' }, { field: 'content', name: 'message' }])
  end

  it 'does not keep project as a second spelling' do
    expect { described_class.new('messages | project id').parse }.to raise_error(Wootql::Error, /Unknown WootQL stage: project/)
  end

  it 'keeps parenthesized membership values distinct from a collection parameter' do
    predicate = described_class.new('messages | where conversation_id in (1, $id)').parse.stages.first[:arguments]
    expect(predicate[:value]).to eq([{ literal: 1 }, { parameter: 'id' }])
  end

  it 'accepts a field reference on the right side of a comparison' do
    predicate = described_class.new('messages | where created_at > conversation.last_activity_at').parse.stages.first[:arguments]
    expect(predicate[:value]).to eq(field: 'conversation.last_activity_at')
  end

  it 'does not confuse quoted strings with field references' do
    predicate = described_class.new('messages | where content = "conversation.status"').parse.stages.first[:arguments]
    expect(predicate[:value]).to eq(literal: 'conversation.status')
  end

  it 'preserves not, and, or precedence' do
    predicate = described_class.new('messages | where not private = true and id > 2 or id = 1').parse.stages.first[:arguments]
    expect(predicate[:operator]).to eq('or')
    expect(predicate[:left][:operator]).to eq('and')
    expect(predicate[:left][:left][:operator]).to eq('not')
  end

  ['messages | where id in ()', 'messages | where id in (1,)', 'messages | where id = 1; DROP TABLE messages',
   'messages | return id + 1', 'messages | join contacts as c on contact_id != c.id'].each do |source|
    it "rejects unsupported syntax: #{source}" do
      expect { described_class.new(source).parse }.to raise_error(Wootql::Error)
    end
  end

  it 'attaches source location and stage information to parsing failures' do
    expect { described_class.new("messages\n| where id =").parse }.to raise_error(Wootql::Error) { |error|
      expect(error.evidence.join(' ')).to include('line 2', 'where')
    }
  end

  it 'rejects overlong queries before tokenizing' do
    expect { described_class.new('x' * 32_769).parse }.to raise_error(Wootql::Error, /32 KB/)
  end

  it 'bounds the number of pipeline stages' do
    expect { described_class.new("messages#{' | take 1' * 33}").parse }.to raise_error(Wootql::Error, /32 stages/)
  end
end

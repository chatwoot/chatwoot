require 'spec_helper'
require_relative 'query_context'

RSpec.describe Wootql::Schema do
  include_context 'with a WootQL catalog'

  it 'describes the built-in catalog without caller configuration' do
    description = described_class.new.describe(data)
    expect(description.keys).to eq(catalog.keys)
    expect(description.fetch('conversations')[:fields]['status']).to eq(type: :string, values: %w[open resolved])
    expect(description.fetch('messages')[:relations]['conversation']).to eq(['conversations', 'conversation_id', :one])
  end

  it 'keeps field exposure and computed labels consistent with Chatwoot discovery' do
    fields = described_class.new.fields('conversations', data.scope('conversations'))
    expect(fields.keys).to eq(catalog.fetch('conversations').fetch(:fields) + ['labels'])
    expect(fields.fetch('labels').expression).to eq('ARRAY[]::text[]')
  end

  it 'does not accept a custom catalog or arbitrary computed SQL' do
    expect { described_class.new(catalog: catalog) }.to raise_error(ArgumentError)
    expect { described_class.new.expression('messages', 'custom_sql') }.to raise_error(Wootql::Error, /Unknown computed query field/)
  end
end

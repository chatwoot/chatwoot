# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wootql::Query do
  it 'instruments parsing, resolution, and execution without recording row values' do
    spans = []
    instrument = lambda do |stage, attributes, &block|
      span = instance_double(OpenTelemetry::Trace::Span, set_attribute: nil)
      spans << [stage, attributes]
      block.call(span)
    end
    query = described_class.new(data: instance_double(Captain::Apropos::DataAccess), budget: { queries: 0 }, instrument: instrument)
    ast = Wootql::Parser::Query.new(resource: 'contacts', stages: [])
    plan = instance_double(Wootql::Resolver::Plan, fields: { 'id' => :integer, 'email' => :string })
    allow(Wootql::Parser).to receive(:new).and_return(instance_double(Wootql::Parser, parse: ast))
    allow(Wootql::Resolver).to receive(:new).and_return(instance_double(Wootql::Resolver, resolve: plan))
    allow(query).to receive(:page).and_return('items' => [{ 'id' => 1, 'email' => 'secret@example.com' }], 'next_offset' => false)

    result = query.run('contacts | return id, email')

    expect(result.fetch('items').sole.fetch('email')).to eq('secret@example.com')
    expect(spans.map(&:first)).to eq(%w[parse resolve query execute])
    expect(spans.to_json).not_to include('secret@example.com')
    expect(spans.assoc('parse').last).to include('wootql.source_bytes' => 'contacts | return id, email'.bytesize)
  end
end

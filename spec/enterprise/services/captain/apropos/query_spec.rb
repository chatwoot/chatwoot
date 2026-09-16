# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Apropos::Query do
  it 'instruments parsing, resolution, and execution without recording row values' do
    spans = []
    instrument = lambda do |stage, attributes, &block|
      span = instance_double(OpenTelemetry::Trace::Span, set_attribute: nil)
      spans << [stage, attributes]
      block.call(span)
    end
    query = described_class.new(data: instance_double(Captain::Apropos::DataAccess), budget: { queries: 0 }, instrument: instrument)
    ast = Captain::Apropos::WootqlParser::Query.new(resource: 'contacts', stages: [])
    plan = instance_double(Captain::Apropos::WootqlResolver::Plan, fields: { 'id' => :integer, 'email' => :string })
    allow(Captain::Apropos::WootqlParser).to receive(:new).and_return(instance_double(Captain::Apropos::WootqlParser, parse: ast))
    allow(Captain::Apropos::WootqlResolver).to receive(:new).and_return(instance_double(Captain::Apropos::WootqlResolver, resolve: plan))
    allow(query).to receive(:page).and_return('items' => [{ 'id' => 1, 'email' => 'secret@example.com' }], 'next_offset' => false)

    result = query.run('contacts | project id, email')

    expect(result.fetch('items').sole.fetch('email')).to eq('secret@example.com')
    expect(spans.map(&:first)).to eq(%w[query parse resolve execute])
    expect(spans.to_json).not_to include('secret@example.com')
    expect(spans.assoc('query').last).to include('wootql.source' => 'contacts | project id, email')
  end
end

require 'rails_helper'

RSpec.describe CopilotRun::Collection do
  it 'describes how a chained selection was made, earliest step first' do
    csat = described_class.new(context: { 'resource' => 'csat', 'filters' => { 'at_most' => { 'rating' => 2 } } })
    conversations = described_class.new(context: { 'resource' => 'conversations', 'filters' => {} }, source_run: csat)

    expect(conversations.selection).to eq('csat with filters {"at_most":{"rating":2}}, then the conversations with filters {} linked to them')
  end
end

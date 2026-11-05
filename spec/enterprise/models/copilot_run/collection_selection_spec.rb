require 'rails_helper'

RSpec.describe CopilotRun::Collection do
  it 'describes how a chained selection was made, earliest step first' do
    csat = described_class.new(context: { 'resource' => 'csat', 'filters' => { 'at_most' => { 'rating' => 2 } } })
    conversations = described_class.new(context: { 'resource' => 'conversations', 'filters' => {} }, source_run: csat)

    expect(conversations.selection).to eq('csat with filters {"at_most":{"rating":2}}, then the conversations with filters {} linked to them')
  end

  it 'keeps the steps before a review in the description of a selection made from its matches' do
    csat = described_class.new(context: { 'resource' => 'csat', 'filters' => { 'at_most' => { 'rating' => 2 } } })
    conversations = described_class.new(context: { 'resource' => 'conversations', 'filters' => {} }, source_run: csat)
    review = CopilotRun::Review.new(context: { 'question' => 'Did the agent apologise?' }, source_run: conversations)
    matched = described_class.new(context: { 'resource' => 'conversations', 'filters' => {} }, source_run: review)

    expect(matched.selection).to start_with('csat with filters {"at_most":{"rating":2}}, then the conversations with filters {} linked to them, ' \
                                            'then the conversations a review of them matched (Did the agent apologise?)')
  end
end

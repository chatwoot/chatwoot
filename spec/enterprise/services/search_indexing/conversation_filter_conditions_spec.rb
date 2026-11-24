require 'rails_helper'

RSpec.describe SearchIndexing::ConversationFilterConditions do
  def condition(field, operator, values = [], **options)
    { attribute_key: field, filter_operator: operator, values: values, query_operator: nil }.merge(options)
  end

  it 'preserves AND precedence in a mixed OR expression' do
    payload = [condition('status', 'equal_to', ['open'], query_operator: 'OR'),
               condition('team_id', 'equal_to', ['12'], query_operator: 'AND'), condition('priority', 'equal_to', ['high'])]
    query = described_class.new(payload).query
    expect(query.dig(:bool, :should)).to eq([
                                              { bool: { filter: [{ terms: { 'status' => ['open'] } }] } },
                                              { bool: { filter: [{ terms: { 'team_id' => [12] } }, { terms: { 'priority' => ['high'] } }] } }
                                            ])
  end

  it 'excludes missing fields from negative comparisons like PostgreSQL' do
    query = described_class.new([condition('priority', 'not_equal_to', ['high'])]).query
    expect(query.dig(:bool, :should, 0, :bool, :filter, 0)).to eq(
      bool: { filter: [{ exists: { field: 'priority' } }], must_not: [{ terms: { 'priority' => ['high'] } }] }
    )
  end

  it 'treats a bot assignee as assigned for presence filters' do
    query = described_class.new([condition('assignee_id', 'is_not_present')]).query
    expect(query.dig(:bool, :should, 0, :bool, :filter, 0)).to eq(
      bool: { must_not: [{ exists: { field: 'assignee_id' } }, { exists: { field: 'assignee_agent_bot_id' } }] }
    )
  end

  it 'uses the next local midnight for greater-than date comparisons' do
    payload = [condition('created_at', 'is_greater_than', ['2026-03-08'], timezone: 'America/New_York')]
    query = described_class.new(payload).query
    expect(query.dig(:bool, :should, 0, :bool, :filter, 0)).to eq(range: { 'created_at' => { gte: '2026-03-09T04:00:00Z' } })
  end

  it 'falls back for any unsupported field in the request' do
    payload = [condition('status', 'equal_to', ['open'], query_operator: 'OR'), condition('labels', 'equal_to', ['urgent'])]
    expect(described_class.new(payload).query).to be_nil
  end
end

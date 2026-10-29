require 'rails_helper'

RSpec.describe Captain::Copilot::Aggregation do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account, name: 'Sojan') }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversations) { Captain::Copilot::Resources.build('conversations', account: account, user: admin) }
  let(:relation) { conversations.matching(conversations.normalize({}), as_of: Time.current) }
  let(:aggregation) { described_class.new(conversations, relation, time_zone: 'UTC', date_field: 'created_at') }

  # Wednesday 6 September 2023 at 12:10 and 12:40, and Thursday 7 September at 09:00.
  before do
    create(:conversation, account: account, inbox: inbox, assignee: agent, created_at: Time.utc(2023, 9, 6, 12, 10),
                          first_reply_created_at: Time.utc(2023, 9, 6, 13, 10))
    create(:conversation, account: account, inbox: inbox, assignee: agent, created_at: Time.utc(2023, 9, 6, 12, 40),
                          first_reply_created_at: Time.utc(2023, 9, 6, 15, 40))
    create(:conversation, account: account, inbox: inbox, created_at: Time.utc(2023, 9, 7, 9, 0), first_reply_created_at: Time.utc(2023, 9, 7, 9, 30))
  end

  it 'counts records by weekday and hour' do
    result = aggregation.call(measure: 'count', group_by: %w[created_at:day_of_week created_at:hour_of_day])

    expect(result[:groups]).to contain_exactly({ group: %w[Wednesday 12:00], value: 2 }, { group: %w[Thursday 09:00], value: 1 })
  end

  it 'cuts periods in the time zone it is given' do
    result = described_class.new(conversations, relation, time_zone: 'Asia/Kolkata', date_field: 'created_at').call(measure: 'count',
                                                                                                                    group_by: ['day'])

    expect(result[:groups]).to eq([{ group: '2023-09-06', value: 2 }, { group: '2023-09-07', value: 1 }])
  end

  it 'groups by another date column without dropping records whose value falls outside the dates of date_field' do
    range = Time.utc(2023, 9, 6)...Time.utc(2023, 9, 6, 14)

    result = described_class.new(conversations, relation.where(created_at: range), time_zone: 'UTC', date_field: 'created_at', range: range)
                            .call(measure: 'count', group_by: ['first_reply_created_at:day'])

    expect(result[:groups]).to eq([{ group: '2023-09-06', value: 2 }])
  end

  it 'orders medians by hour as numbers' do
    result = aggregation.call(measure: 'median', duration: %w[created_at first_reply_created_at], group_by: ['created_at:hour_of_day'])

    expect(result[:groups].pluck(:group)).to eq(%w[09:00 12:00])
  end

  it 'measures the time between two date columns per agent, named, with unassigned ones apart' do
    average = aggregation.call(measure: 'average', duration: %w[created_at first_reply_created_at], group_by: ['assignee'])
    median = aggregation.call(measure: 'median', duration: %w[created_at first_reply_created_at], group_by: ['assignee'])

    expect(average).to include(unit: 'hours', groups: [{ group: "Sojan (ID #{agent.id})", value: 2.0 }], without_value: 0.5)
    expect(median[:groups]).to eq([{ group: "Sojan (ID #{agent.id})", value: 2.0 }])
  end

  it 'takes the median of one column without groups' do
    middle = account.conversations.order(:display_id).pluck(:display_id).second

    expect(aggregation.call(measure: 'median', column: 'display_id')[:value]).to eq(middle)
  end

  it 'groups by label, counting a record once per label and unlabeled ones apart' do
    account.conversations.first.update!(label_list: %w[billing refund])

    expect(aggregation.call(measure: 'count', group_by: ['label']))
      .to include(groups: contain_exactly({ group: 'billing', value: 1 }, { group: 'refund', value: 1 }), without_value: 2)
  end

  it 'groups by a key inside a JSON column' do
    account.conversations.first.update!(additional_attributes: { 'browser_language' => 'es' })

    expect(aggregation.call(measure: 'count', group_by: ['additional_attributes.browser_language']))
      .to include(groups: [{ group: 'es', value: 1 }], without_value: 2)
  end

  it 'refuses to group by a JSON key that holds objects, so their nested values never reach the labels' do
    account.conversations.first.update!(additional_attributes: { 'browser' => { 'name' => 'Firefox' } })

    expect { aggregation.call(measure: 'count', group_by: ['additional_attributes.browser']) }
      .to raise_error(ArgumentError, 'additional_attributes.browser holds objects or lists; group by a key with plain values')
  end

  it 'groups by a field the resource adds, such as the country of contacts, with contacts without one apart' do
    create(:contact, account: account, additional_attributes: { 'country' => 'India' })
    create(:contact, account: account)
    contacts = Captain::Copilot::Resources.build('contacts', account: account, user: admin)

    result = described_class.new(contacts, account.contacts, time_zone: 'UTC', date_field: 'created_at').call(measure: 'count', group_by: ['country'])

    expect(result).to include(groups: [{ group: 'India', value: 1 }], without_value: account.contacts.count - 1)
  end

  it 'keeps the largest groups and the records without a value when there are too many groups' do
    stub_const("#{described_class}::MAX_GROUPS", 1)
    busier = create(:user, account: account, name: 'Muhsin')
    create_list(:conversation, 3, account: account, inbox: inbox, assignee: busier, created_at: Time.utc(2023, 9, 8))

    expect(aggregation.call(measure: 'count', group_by: ['assignee']))
      .to include(groups: [{ group: "Muhsin (ID #{busier.id})", value: 3 }], without_value: 1, cut: be_present)
  end

  it 'takes the two date columns of a duration in any order' do
    expect(aggregation.call(measure: 'average', duration: %w[first_reply_created_at last_activity_at]))
      .to include(of: 'time from first_reply_created_at to last_activity_at', unit: 'hours')
  end

  it 'rejects a date column without a part and a column that is not numeric' do
    expect { aggregation.call(measure: 'count', group_by: ['created_at']) }.to raise_error(ArgumentError, /group it by a part/)
    expect { aggregation.call(measure: 'sum', column: 'status') }.to raise_error(ArgumentError, /not a numeric column/)
  end
end

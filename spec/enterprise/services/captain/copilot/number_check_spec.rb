require 'rails_helper'

RSpec.describe Captain::Copilot::NumberCheck do
  let(:results) { [{ total: 1899, matched: 28, active_misses: 11, groups: [{ group: 'Pranav', value: 52.27 }] }.to_json, '{"seconds":7380}'] }
  let(:check) { described_class.new(results) }

  it 'accepts numbers the results show, round, add up, subtract, divide or convert from seconds' do
    draft = 'We found 1,899 conversations. 28 missed the SLA and 11 more are still open, 39 in all, 17 apart. That is 1.47% of them. ' \
            'Pranav averaged 52.3 hours, and the longest wait was 2.05 hours.'

    expect(check.unsupported(draft)).to eq([])
  end

  it 'accepts a percentage change and working the draft shows, such as a sum and then its share' do
    check = described_class.new([{ four_stars: 12, five_stars: 18, rated: 76, last_week: 202, this_week: 64 }.to_json])

    expect(check.unsupported('Resolutions fell from 202 to 64, down 68.3%. 30 of 76 ratings were 4 or 5 stars, 39.47% of them.')).to eq([])
  end

  it 'does not check questions back to the agent' do
    expect(check.unsupported('Should I list the top 4,321 or the top 9,876?')).to eq([])
    expect(check.unsupported('I will list the top 4,321.')).to eq([{ number: '4321', sentence: 'I will list the top 4,321.' }])
  end

  it 'leaves out dates, links, conversation references and list markers' do
    draft = "1. On 2023-09-04T10:00:00Z at 10:30, [#4321](/app/accounts/7/conversations/4321) reopened.\n2. See #5678."

    expect(check.unsupported(draft)).to eq([])
  end

  it 'flags a number no result supports, such as an average of two averages, with its sentence' do
    check = described_class.new([{ groups: [{ group: 'Email', value: 10 }, { group: 'Chat', value: 20 }] }.to_json])

    expect(check.unsupported('Email takes 10 hours and chat 20. Overall the average is 15 hours.'))
      .to eq([{ number: '15', sentence: 'Overall the average is 15 hours.' }])
  end
end

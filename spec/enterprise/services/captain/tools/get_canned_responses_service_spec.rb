require 'rails_helper'

RSpec.describe Captain::Tools::GetCannedResponsesService do
  subject(:tool) { described_class.new(account: account) }

  let(:account) { create(:account) }

  before do
    create(:canned_response, account: account, short_code: 'DPA', content: 'Email legal@example.com to request the data processing agreement.')
    create(:canned_response, account: account, short_code: 'trial-code', content: 'Use the trial code to extend your trial.')
  end

  describe '.index_for' do
    it 'lists each canned response by name with the start of its text' do
      index = described_class.index_for(account)

      expect(index).to include('- DPA: Email legal@example.com to request the data processing agreement.')
      expect(index).to include('- trial-code: Use the trial code to extend your trial.')
    end
  end

  it 'returns the full text of the named canned responses, ignoring case and a leading slash' do
    result = tool.execute(names: ['/dpa', 'trial-code'])

    expect(result).to include("<saved_reply name=\"DPA\">\nEmail legal@example.com")
    expect(result).to include("<saved_reply name=\"trial-code\">\nUse the trial code")
  end

  it 'says when a name does not exist' do
    expect(tool.execute(names: ['refund-policy'])).to include('No saved reply named refund-policy.')
  end

  it 'never returns another account’s canned responses' do
    create(:canned_response, account: create(:account), short_code: 'refund-policy', content: 'Another account refund policy.')

    expect(tool.execute(names: ['refund-policy'])).not_to include('Another account')
  end

  it 'returns the exact name when another name differs only by case' do
    create(:canned_response, account: account, short_code: 'dpa', content: 'Our short DPA summary.')

    exact = tool.execute(names: ['DPA'])

    expect(exact).to include('Email legal@example.com')
    expect(exact).not_to include('short DPA summary')
    expect(tool.execute(names: ['dpa'])).to include('Our short DPA summary.')
  end

  it 'reads a name that contains a comma' do
    create(:canned_response, account: account, short_code: 'refund, EU', content: 'EU refunds take 14 days.')

    expect(tool.execute(names: ['refund, EU'])).to include("<saved_reply name=\"refund, EU\">\nEU refunds take 14 days.\n</saved_reply>")
  end

  it 'reads the first three names when given more' do
    create(:canned_response, account: account, short_code: 'refund', content: 'Refunds take 5 days.')
    create(:canned_response, account: account, short_code: 'extra', content: 'Not read.')

    result = tool.execute(names: %w[DPA trial-code refund extra])

    expect(result).to include('name="DPA"', 'name="trial-code"', 'name="refund"')
    expect(result).not_to include('Not read.')
  end

  it 'rejects malformed names' do
    expect(tool.execute(names: 'dpa')).to include('one to three saved reply names')
    expect(tool.execute(names: [])).to include('one to three saved reply names')
    expect(tool.execute(names: [1])).to include('one to three saved reply names')
    expect(tool.execute(names: [''])).to include('one to three saved reply names')
    expect(tool.execute).to include('one to three saved reply names')
  end

  it 'stops after the call limit for one draft' do
    described_class::MAX_CALLS.times { tool.execute(names: ['dpa']) }

    expect(tool.execute(names: ['dpa'])).to include('limit')
  end
end

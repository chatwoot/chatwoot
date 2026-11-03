require 'rails_helper'

RSpec.describe Captain::FilterTextSpan do
  subject(:span) { described_class.new(field: { key: 'email', label: 'Email' }, index: 3, query: query) }

  let(:query) { 'Contacts named John Smith' }

  def choice(choice, probability)
    { 'type' => 'choice', 'choice' => choice, 'probabilities' => { choice => probability } }
  end

  it 'keeps emails and domains whole and drops quotes and trailing punctuation' do
    words = described_class.words('Email from "chatwoot.com", or john@acme.io.')

    expect(words.pluck(:text)).to eq(%w[Email from chatwoot.com or john@acme.io])
    expect(described_class.word_list('Email from chatwoot.com')).to eq("0|Email\n1|from\n2|chatwoot.com")
  end

  it 'offers every word and none as answers' do
    expect(span.questions['start_3'][:criteria]).to eq(
      'none' => '`description` gives no value for this field', '0' => 'Contacts', '1' => 'named', '2' => 'John', '3' => 'Smith'
    )
  end

  it 'returns the original text between the first and last word' do
    expect(span.values('start_3' => choice('2', 0.9), 'end_3' => choice('3', 0.94))).to eq(['John Smith'])
  end

  it 'uses the one word Jev is sure of when it is unsure of the other end' do
    expect(span.values('start_3' => choice('none', 0.59), 'end_3' => choice('3', 0.68))).to eq(['Smith'])
  end

  it 'returns no value when Jev finds none or the ends are reversed' do
    expect(span.values('start_3' => choice('none', 0.8), 'end_3' => choice('none', 0.8))).to eq([])
    expect(span.values('start_3' => choice('3', 0.9), 'end_3' => choice('2', 0.9))).to eq([])
  end
end

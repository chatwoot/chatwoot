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

  it 'offers every word and none as answers, in a broad and a strict reading' do
    expect(span.questions.keys).to eq(%w[start_broad_3 end_broad_3 start_strict_3 end_strict_3])
    expect(span.questions['start_broad_3'][:criteria]).to eq(
      'none' => '`description` gives no value for this field', '0' => 'Contacts', '1' => 'named', '2' => 'John', '3' => 'Smith'
    )
  end

  def readings(broad_start, broad_end, strict_start, strict_end)
    {
      'start_broad_3' => broad_start, 'end_broad_3' => broad_end,
      'start_strict_3' => strict_start, 'end_strict_3' => strict_end
    }
  end

  it 'returns the original text between the first and last word' do
    answers = readings(choice('2', 0.9), choice('3', 0.94), choice('2', 0.9), choice('3', 0.9))

    expect(span.values(answers)).to eq(['John Smith'])
  end

  it 'keeps the words both readings agree on' do
    answers = readings(choice('0', 0.8), choice('3', 0.9), choice('3', 0.9), choice('3', 0.9))

    expect(span.values(answers)).to eq(['Smith'])
  end

  it 'uses the one word Jev is sure of when it is unsure of the other end' do
    answers = readings(choice('none', 0.59), choice('3', 0.68), choice('none', 0.7), choice('none', 0.7))

    expect(span.values(answers)).to eq(['Smith'])
  end

  it 'returns no value when Jev finds none, the ends are reversed, or the readings share no words' do
    expect(span.values(readings(*Array.new(4) { choice('none', 0.8) }))).to eq([])
    expect(span.values(readings(choice('3', 0.9), choice('2', 0.9), choice('none', 0.8), choice('none', 0.8)))).to eq([])
    expect(span.values(readings(choice('0', 0.9), choice('1', 0.9), choice('3', 0.9), choice('3', 0.9)))).to eq([])
  end
end

require 'rails_helper'

RSpec.describe Captain::FaqImports::Parser do
  let(:assistant) { create(:captain_assistant) }

  def parse(content)
    described_class.new(assistant: assistant, content: content).perform
  end

  it 'accepts normalized headers and quoted commas and line breaks' do
    rows = parse(" Question ,ANSWER\n\"Where, exactly?\",\"On the first\nfloor\"\n")

    expect(rows.first).to include(
      'question' => 'Where, exactly?',
      'answer' => "On the first\nfloor",
      'state' => 'valid'
    )
  end

  it 'accepts a UTF-8 byte order mark' do
    rows = parse("\uFEFFquestion,answer\nQuestion,Answer\n".b)

    expect(rows.first['state']).to eq('valid')
  end

  it 'accepts UTF-8 CSV content read as binary' do
    rows = parse("question,answer\nWhat’s included?,Everything\n".b)

    expect(rows.first).to include(
      'question' => 'What’s included?',
      'answer' => 'Everything',
      'state' => 'valid'
    )
  end

  it 'rejects content that is not valid UTF-8' do
    expect { parse("question,answer\nQuestion,\xFF\n".b) }
      .to raise_error(described_class::InvalidCsvError, 'The CSV must use UTF-8 encoding.')
  end

  it 'rejects missing and additional columns' do
    expect { parse("question\nWhere?\n") }
      .to raise_error(described_class::InvalidCsvError, /exactly two columns/)
    expect { parse("question,answer,notes\nWhere?,Here,Extra\n") }
      .to raise_error(described_class::InvalidCsvError, /exactly two columns/)
  end

  it 'rejects more than 1,000 data rows' do
    content = CSV.generate do |csv|
      csv << %w[question answer]
      1001.times { |index| csv << ["Question #{index}", 'Answer'] }
    end

    expect { parse(content) }.to raise_error(described_class::InvalidCsvError, /at most 1000 rows/)
  end

  it 'marks blank values and extra row values as invalid' do
    rows = parse("question,answer\n,Answer\nQuestion,Answer,Extra\n")

    expect(rows.map { |row| row.slice('state', 'error') }).to eq(
      [
        { 'state' => 'invalid', 'error' => 'Question is required.' },
        { 'state' => 'invalid', 'error' => 'Expected two columns.' }
      ]
    )
  end

  it 'skips repeated rows after normalizing whitespace and capitalization' do
    rows = parse("question,answer\nHow   does it work?,Very well\n\" how\ndoes IT work? \", very   WELL \n")

    expect(rows.map { |row| row['state'] }).to eq(%w[valid duplicate])
  end

  it 'marks every repeated question with different answers as invalid' do
    rows = parse("question,answer\nHow does it work?,First answer\nHOW DOES IT WORK?,Second answer\n")

    expect(rows.map { |row| row['state'] }).to eq(%w[invalid invalid])
    expect(rows.map { |row| row['error'] }.uniq).to eq(['The same question has different answers.'])
  end

  it 'keeps punctuation significant when matching existing FAQs' do
    existing = create(:captain_assistant_response, assistant: assistant, question: 'Where is it?', answer: 'Here')

    rows = parse("question,answer\n where   IS it? ,Imported\nWhere is it,Other\n")

    expect(rows.first).to include('state' => 'existing', 'existing_id' => existing.id, 'existing_answer' => 'Here')
    expect(rows.second['state']).to eq('valid')
  end
end

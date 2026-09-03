require 'rails_helper'

describe Integrations::MutodayFaqReply::DenyList do
  let(:deny_list) { described_class }

  describe '.match — the dangerous topics' do
    # rubocop:disable Style/WordArray -- these are Thai sentences, and %w mangles them
    {
      crisis: ['อยากตายแล้ว', 'คิดจะฆ่าตัวตาย', 'ทำร้ายตัวเองไปแล้ว'],
      money: ['ขอเงินคืนหน่อยครับ', 'โดนตัดเงินซ้ำสองรอบ', 'อยากยกเลิกสมาชิกครับ'],
      complaint: ['จะร้องเรียนเรื่องนี้', 'บริการแย่มากครับ', 'โดนโกงเงินไปแล้ว'],
      legal: ['จะฟ้องร้องแล้วนะ', 'ปรึกษาทนายไว้แล้ว', 'จะไปแจ้งความครับ'],
      human: ['ขอคุยกับคนหน่อย', 'ขอเจ้าหน้าที่ครับ', 'อยากคุยกับแอดมิน'],
      credential: ['เลขบัตรประชาชนคืออะไร', 'ลืมรหัสผ่านครับ', 'ขอเลขบัญชีหน่อย']
    }.each do |topic, phrasings|
      it "returns :#{topic} for #{phrasings.size} different phrasings" do
        phrasings.each do |text|
          expect(deny_list.match(text)).to eq(topic), "expected #{text.inspect} to be :#{topic}, got #{deny_list.match(text).inspect}"
        end
      end
    end
    # rubocop:enable Style/WordArray
  end

  describe '.match — the ASCII terms' do
    it 'matches whole words' do
      expect(deny_list.match('I want a refund')).to eq(:money)
      expect(deny_list.match('send me the OTP')).to eq(:credential)
      expect(deny_list.match('talk to a human please')).to eq(:human)
    end

    it 'respects word boundaries, so a term buried in a longer word does not fire' do
      ['I will adopt a cat', 'the operators manual', 'refundable deposit rules'].each do |text|
        expect(deny_list.match(text)).to be_nil, "expected #{text.inspect} to be nil, got #{deny_list.match(text).inspect}"
      end
    end
  end

  describe 'the ordinary-message fixtures' do
    described_class::NON_MATCHING_FIXTURES.each do |fixture|
      it "returns nil for #{fixture}" do
        expect(deny_list.match(fixture)).to be_nil
      end
    end

    it 'covers 15 fixtures' do
      expect(described_class::NON_MATCHING_FIXTURES.size).to eq(15)
    end
  end

  # The rule that keeps the list honest, checked mechanically rather than by eye.
  describe 'the term-addition rule' do
    let(:all_fixtures) do
      described_class::NON_MATCHING_FIXTURES + described_class::CORPUS_QUESTION_FIXTURES
    end

    it 'has no term that is a substring of an ordinary message or an approved question' do
      offenders = described_class::ALL_TERMS.flat_map do |term|
        all_fixtures
          .select { |fixture| fixture.downcase.include?(term.downcase) }
          .map { |fixture| "#{term.inspect} is inside #{fixture.inspect}" }
      end

      expect(offenders).to be_empty
    end

    it 'has no term that is a substring of a normalised fixture either' do
      normalised = all_fixtures.map { |fixture| described_class.normalise(fixture) }
      offenders = described_class::ALL_TERMS.flat_map do |term|
        normalised
          .select { |fixture| fixture.include?(term.downcase) }
          .map { |fixture| "#{term.inspect} is inside #{fixture.inspect}" }
      end

      expect(offenders).to be_empty
    end

    it 'has every Thai term at least 3 characters long' do
      short = described_class::THAI_TERMS.values.flatten.select { |term| term.length < 3 }

      expect(short).to be_empty
    end

    it 'has no term that another term already covers' do
      all = described_class::ALL_TERMS
      shadowed = all.select { |term| all.any? { |other| other != term && term.include?(other) } }

      expect(shadowed).to be_empty
    end

    it 'never lists the same term under two topics' do
      terms = described_class::ALL_TERMS

      expect(terms).to eq(terms.uniq)
    end
  end

  # C7 — the corpus's own headline question was in the deny list verbatim, so that answer
  # could never have shipped.
  describe 'the questions the corpus exists to answer' do
    described_class::CORPUS_QUESTION_FIXTURES.each do |question|
      it "returns nil for #{question}" do
        expect(deny_list.match(question)).to be_nil
      end
    end
  end

  describe 'เสียหาย' do
    it 'is a complaint, and is listed under exactly one topic' do
      expect(deny_list.match('สินค้าเสียหายครับ')).to eq(:complaint)

      owners = described_class::THAI_TERMS.select { |_topic, terms| terms.include?('เสียหาย') }.keys
      expect(owners).to eq([:complaint])
    end

    it 'no longer has a money term that swallows it' do
      swallowing = described_class::THAI_TERMS[:money].select { |term| term.include?('เสียหาย') }

      expect(swallowing).to be_empty
    end
  end

  describe '.normalise' do
    it 'strips politeness particles from the tail until stable' do
      expect(described_class.normalise('ขอเงินคืนหน่อยครับ')).to eq('ขอเงินคืน')
      expect(described_class.normalise('ขอเงินคืนด้วยนะครับ')).to eq('ขอเงินคืน')
    end

    it 'strips trailing punctuation' do
      expect(described_class.normalise('ขอเงินคืนครับ?')).to eq('ขอเงินคืน')
      expect(described_class.normalise('ขอเงินคืน!!!')).to eq('ขอเงินคืน')
    end

    it 'collapses whitespace and downcases' do
      expect(described_class.normalise("  I  want a\nREFUND ")).to eq('i want a refund')
    end

    it 'never strips a message down to nothing' do
      expect(described_class.normalise('ครับ')).to eq('ครับ')
      expect(described_class.normalise('ค่ะ')).to eq('ค่ะ')
    end
  end

  describe 'degenerate input' do
    it 'returns nil without raising' do
      [nil, '', '   ', "\n\n", '?', '...', 'ครับ', '👍'].each do |text|
        expect { deny_list.match(text) }.not_to raise_error
        expect(deny_list.match(text)).to be_nil
      end
    end
  end

  describe 'topic ordering' do
    it 'labels a message carrying both a crisis phrase and another topic as crisis' do
      expect(deny_list.match('อยากตาย โดนโกงเงินไปหมดแล้ว')).to eq(:crisis)
      expect(deny_list.match('โดนโกงเงินไปหมดแล้ว อยากตาย')).to eq(:crisis)
    end
  end
end

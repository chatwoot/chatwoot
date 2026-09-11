# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Widget::IncomingContentSanitizer do
  describe '.sanitize' do
    it 'returns blank content unchanged' do
      expect(described_class.sanitize(nil)).to be_nil
      expect(described_class.sanitize('')).to eq('')
    end

    it 'keeps ordinary text and markdown' do
      expect(described_class.sanitize('hello **there**')).to eq('hello **there**')
    end

    it 'strips HTML tags and event-handler payloads' do
      raw = '<img src=x onerror=alert(1)>hello'
      expect(described_class.sanitize(raw)).to eq('hello')
    end

    it 'strips template wrappers used in known DOMPurify bypasses' do
      raw = '<template><img src=x onerror=alert(1)></template>safe'
      expect(described_class.sanitize(raw)).to eq('safe')
    end

    it 'keeps CommonMark URL and email autolinks' do
      expect(described_class.sanitize('Visit <https://example.com> please')).to eq(
        'Visit <https://example.com> please'
      )
      expect(described_class.sanitize('Write <support@example.com>')).to eq(
        'Write <support@example.com>'
      )
      expect(described_class.sanitize('Get <ftp://files.example.com>')).to eq(
        'Get <ftp://files.example.com>'
      )
      expect(described_class.sanitize('Mail <mailto:support@example.com>')).to eq(
        'Mail <mailto:support@example.com>'
      )
    end

    it 'does not park javascript or data URI autolinks' do
      expect(described_class.sanitize('<javascript:alert(1)>')).not_to include('javascript:')
      expect(described_class.sanitize('<data:text/html,alert(1)>')).not_to include('data:')
    end

    it 'does not park HTML that merely contains an @' do
      raw = '<svg/onload=alert(1)//@x>hello'
      expect(described_class.sanitize(raw)).not_to include('onload')
      expect(described_class.sanitize(raw)).not_to include('<svg')
    end

    it 'does not parse HTML when the original content exceeds the message limit' do
      sanitizer = instance_double(Rails::HTML5::FullSanitizer)
      allow(Rails::HTML5::FullSanitizer).to receive(:new).and_return(sanitizer)
      expect(sanitizer).not_to receive(:sanitize)

      raw = "<b>#{'h' * (described_class::MAX_CONTENT_LENGTH + 1)}</b>"
      expect(described_class.sanitize(raw)).to eq(raw)
    end
  end
end

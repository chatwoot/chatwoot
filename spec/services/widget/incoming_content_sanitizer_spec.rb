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
    end

    it 'does not park HTML that merely contains an @' do
      raw = '<svg/onload=alert(1)//@x>hello'
      expect(described_class.sanitize(raw)).not_to include('onload')
      expect(described_class.sanitize(raw)).not_to include('<svg')
    end
  end
end

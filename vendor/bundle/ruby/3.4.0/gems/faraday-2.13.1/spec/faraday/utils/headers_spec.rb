# frozen_string_literal: true

RSpec.describe Faraday::Utils::Headers do
  subject { Faraday::Utils::Headers.new }

  context 'when Content-Type is set to application/json' do
    before { subject['Content-Type'] = 'application/json' }

    it { expect(subject.keys).to eq(['Content-Type']) }
    it { expect(subject['Content-Type']).to eq('application/json') }
    it { expect(subject['CONTENT-TYPE']).to eq('application/json') }
    it { expect(subject['content-type']).to eq('application/json') }
    it { is_expected.to include('content-type') }
  end

  context 'when Content-Type is set to application/xml' do
    before { subject['Content-Type'] = 'application/xml' }

    it { expect(subject.keys).to eq(['Content-Type']) }
    it { expect(subject['Content-Type']).to eq('application/xml') }
    it { expect(subject['CONTENT-TYPE']).to eq('application/xml') }
    it { expect(subject['content-type']).to eq('application/xml') }
    it { is_expected.to include('content-type') }
  end

  describe '#fetch' do
    before { subject['Content-Type'] = 'application/json' }

    it { expect(subject.fetch('Content-Type')).to eq('application/json') }
    it { expect(subject.fetch('CONTENT-TYPE')).to eq('application/json') }
    it { expect(subject.fetch(:content_type)).to eq('application/json') }
    it { expect(subject.fetch('invalid', 'default')).to eq('default') }
    it { expect(subject.fetch('invalid', false)).to eq(false) }
    it { expect(subject.fetch('invalid', nil)).to be_nil }
    it { expect(subject.fetch('Invalid') { |key| "#{key} key" }).to eq('Invalid key') }
    it 'calls a block when provided' do
      block_called = false
      expect(subject.fetch('content-type') { block_called = true }).to eq('application/json')
      expect(block_called).to be_falsey
    end
    it 'raises an error if key not found' do
      expected_error = defined?(KeyError) ? KeyError : IndexError
      expect { subject.fetch('invalid') }.to raise_error(expected_error)
    end
  end

  describe '#delete' do
    before do
      subject['Content-Type'] = 'application/json'
      @deleted = subject.delete('content-type')
    end

    it { expect(@deleted).to eq('application/json') }
    it { expect(subject.size).to eq(0) }
    it { is_expected.not_to include('content-type') }
    it { expect(subject.delete('content-type')).to be_nil }
  end

  describe '#dig' do
    before { subject['Content-Type'] = 'application/json' }

    it { expect(subject&.dig('Content-Type')).to eq('application/json') }
    it { expect(subject&.dig('CONTENT-TYPE')).to eq('application/json') }
    it { expect(subject&.dig(:content_type)).to eq('application/json') }
    it { expect(subject&.dig('invalid')).to be_nil }
  end

  describe '#parse' do
    context 'when response headers leave http status line out' do
      let(:headers) { "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n" }

      before { subject.parse(headers) }

      it { expect(subject.keys).to eq(%w[Content-Type]) }
      it { expect(subject['Content-Type']).to eq('text/html') }
      it { expect(subject['content-type']).to eq('text/html') }
    end

    context 'when response headers values include a colon' do
      let(:headers) { "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nLocation: http://httpbingo.org/\r\n\r\n" }

      before { subject.parse(headers) }

      it { expect(subject['location']).to eq('http://httpbingo.org/') }
    end

    context 'when response headers include a blank line' do
      let(:headers) { "HTTP/1.1 200 OK\r\n\r\nContent-Type: text/html\r\n\r\n" }

      before { subject.parse(headers) }

      it { expect(subject['content-type']).to eq('text/html') }
    end

    context 'when response headers include already stored keys' do
      let(:headers) { "HTTP/1.1 200 OK\r\nX-Numbers: 123\r\n\r\n" }

      before do
        h = subject
        h[:x_numbers] = 8
        h.parse(headers)
      end

      it do
        expect(subject[:x_numbers]).to eq('8, 123')
      end
    end
  end
end

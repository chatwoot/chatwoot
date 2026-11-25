require 'rails_helper'

describe Whatsapp::Dialog360RequestOptions do
  let(:guarded_source) { 'app/services/whatsapp/providers/whatsapp_360_dialog_service.rb' }
  let(:source) { Rails.root.join(guarded_source).read }
  let(:calls) { provider_calls(source) }

  # Reads a call to its own closing paren rather than to the first one it meets. This provider
  # writes some calls on one line and some across several, so a line-oriented scan would answer
  # differently for the same shape.
  def provider_calls(text)
    calls = []
    text.to_enum(:scan, /HTTParty\.(?:get|post|put|patch|delete|head)\(/).each do
      start = Regexp.last_match.begin(0)
      depth = 0
      text[start..].each_char.with_index do |char, offset|
        depth += 1 if char == '('
        next unless char == ')'

        depth -= 1
        next unless depth.zero?

        calls << text[start, offset + 1]
        break
      end
    end
    calls
  end

  it 'caps the wait and the retry, because a ceiling alone still costs twice on a read' do
    expect(described_class::DIALOG360_REQUEST_OPTIONS).to eq(timeout: 10, max_retries: 0)
  end

  it 'leaves no call to the provider without the ceiling' do
    unguarded = calls.reject { |call| call.include?('DIALOG360_REQUEST_OPTIONS') }

    expect(unguarded.map { |call| call.lines.first(2).map(&:strip).join(' ') }).to be_empty
  end

  it 'leaves no inline timeout beside the constant, which would be the value actually in force' do
    expect(calls.grep(/timeout:\s*\d/)).to be_empty
  end

  it 'reads every call in the file, so an empty result cannot pass as a clean one' do
    expect(calls.size).to eq(3)
  end

  # One ceiling is right here only while no call carries media in the body. `send_attachment_message`
  # passes a `link`, which is what keeps every request in the same size class as the Graph family's
  # and lets this provider share that family's number. A call that started uploading a file would
  # need its own, so the absence of one is worth failing on.
  it 'carries no media in a body, which is why one ceiling covers every call' do
    expect(source).to include("'link': attachment.download_url")
    expect(source).not_to include('base64')
  end

  it 'sends only through the helper that also classifies a transport failure' do
    expect(source.scan('HTTParty.post(url, **, **DIALOG360_REQUEST_OPTIONS)').size).to eq(1)
    expect(source).to include('include Whatsapp::Dialog360RequestOptions')
  end
end

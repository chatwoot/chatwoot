require 'rails_helper'

describe Whatsapp::ZapiRequestOptions do
  let(:guarded_source) { 'app/services/whatsapp/providers/whatsapp_zapi_service.rb' }
  let(:source) { Rails.root.join(guarded_source).read }
  let(:calls) { provider_calls(source) }

  # Reads a call to its own closing paren rather than to the first one it meets: the bodies here
  # are hashes with parens of their own, several lines down from the verb.
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

  it 'caps the wait and the retry on both, because a ceiling alone still costs twice on a read' do
    expect(described_class::ZAPI_REQUEST_OPTIONS).to eq(timeout: 10, max_retries: 0)
    expect(described_class::ZAPI_SEND_OPTIONS).to eq(timeout: 90, max_retries: 0)
  end

  it 'gives a send more room than a control call, because a send waits on WhatsApp too' do
    expect(described_class::ZAPI_SEND_OPTIONS[:timeout]).to be > described_class::ZAPI_REQUEST_OPTIONS[:timeout]
  end

  it 'leaves no call to the provider without one of the two ceilings' do
    unguarded = calls.reject { |call| call.include?('ZAPI_REQUEST_OPTIONS') || call.include?('ZAPI_SEND_OPTIONS') }

    expect(unguarded.map { |call| call.lines.first(2).map(&:strip).join(' ') }).to be_empty
  end

  it 'refuses a call that names both ceilings, because then neither is the one in force' do
    expect(calls.select { |call| call.include?('**ZAPI_REQUEST_OPTIONS') && call.include?('ZAPI_SEND_OPTIONS') }).to be_empty
  end

  it 'leaves no inline timeout beside the constant, which would be the value actually in force' do
    expect(calls.grep(/timeout:\s*\d/)).to be_empty
  end

  it 'reads every call in the file, so an empty result cannot pass as a clean one' do
    # The canary. Every check above answers "none", and answers it for zero calls too.
    expect(calls.size).to eq(9)
  end

  # The split is the substance: the send ceiling is the one that waits out a forward to WhatsApp,
  # and the control one is deliberately impatient. A call moving between them silently is a call
  # that starts failing on something the provider would have answered, or one that starts holding
  # a worker for a minute and a half.
  it 'keeps exactly one call on the send ceiling, the helper every send goes through' do
    expect(calls.count { |call| call.include?('ZAPI_SEND_OPTIONS') }).to eq(1)
  end

  it 'sends only through that helper' do
    # `post_outgoing` is where the ceiling and the transport classification both live, so a send
    # written straight against HTTParty would miss both at once.
    expect(source.scan('HTTParty.post(url, **, **ZAPI_SEND_OPTIONS)').size).to eq(1)
    expect(source).to include('include Whatsapp::ZapiRequestOptions')
  end
end

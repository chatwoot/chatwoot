require 'rails_helper'

RSpec.describe RequestDeviceInfo do
  def request_double(user_agent:, headers: {})
    headers_obj = ActionDispatch::Http::Headers.from_hash(
      headers.transform_keys { |k| "HTTP_#{k.upcase.tr('-', '_')}" }
    )
    instance_double(ActionDispatch::Request, user_agent: user_agent, remote_ip: '203.0.113.7', headers: headers_obj)
  end

  it 'names the mobile app from its client headers instead of Unknown Browser' do
    info = described_class.new(request_double(
                                 user_agent: 'ChatwootApp/1.0',
                                 headers: {
                                   'X-Chatwoot-Client-Name' => 'Chatwoot Mobile',
                                   'X-Chatwoot-Platform' => 'ios',
                                   'X-Chatwoot-Device-Model' => 'iPhone15,2'
                                 }
                               ))

    expect(info.browser_name).to eq('Chatwoot Mobile')
    expect(info.platform_label).to eq('iPhone')
  end

  it 'labels a legacy okhttp mobile UA as Chatwoot Mobile' do
    info = described_class.new(request_double(user_agent: 'okhttp/4.9.0'))

    expect(info.browser_name).to eq('Chatwoot Mobile')
    expect(info.platform_label).to eq('Android')
  end

  it 'uses the browser name and OS for a normal desktop browser' do
    ua = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
    info = described_class.new(request_double(user_agent: ua))

    expect(info.browser_name).to eq('Chrome')
    expect(info.platform_label).to eq('macOS')
  end
end

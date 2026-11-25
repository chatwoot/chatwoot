require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'Filtered parameters' do
  # rubocop:enable RSpec/DescribeClass
  let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

  # Saving a native inbox's proxy sends it nested under the channel's provider_config, and
  # the URL carries the proxy's credentials.
  it 'keeps a proxy URL out of the request log' do
    params = { 'channel' => { 'provider_config' => { 'proxy_url' => 'socks5://op:segredo@proxy.example:1080', 'mark_as_read' => true } } }

    expect(filter.filter(params)).to eq('channel' => { 'provider_config' => { 'proxy_url' => '[FILTERED]', 'mark_as_read' => true } })
  end
end

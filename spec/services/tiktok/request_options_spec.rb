require 'rails_helper'

# The ceilings for the TikTok family, including the one call that does not go through
# HTTParty and therefore does not show up in any scan of it.
RSpec.describe Tiktok::RequestOptions do
  let(:client) { Tiktok::Client.new(business_id: 'biz-123', access_token: 'token-123') }

  # The send is the call an agent is waiting on, and it is also the one a scan of options
  # is least likely to be written for, since it sits in a private method.
  it 'bounds the send' do
    options = nil
    allow(HTTParty).to receive(:post) do |_url, **kwargs|
      options = kwargs
      instance_double(HTTParty::Response, success?: true,
                                          body: { code: 0, data: { message: { message_id: 'm1' } } }.to_json)
    end

    client.send_text_message('tt-conv-1', 'hello')

    expect(options).to include(timeout: 10, max_retries: 0)
  end

  # The upload is the only call in this family that carries bytes, and it is the only one
  # a scan for `HTTParty` cannot see: it is a multipart POST over Faraday, which defaults
  # to no ceiling at all. Asserting on the connection object rather than on a request,
  # because what is missing is a default, not an argument.
  it 'bounds the upload, which does not go through HTTParty' do
    connection = client.send(:multipart_connection)

    expect(connection.options.timeout).to eq(120)
    expect(connection.options.open_timeout).to eq(10)
  end

  # The auth client keeps its calls behind `class << self`, and the constant reaches them
  # through the lexical scope rather than through the ancestors of an instance. Counting
  # the constant in the source proves the text is there, not that it resolves: dropping
  # the `include` from this file left every count intact and every example green, because
  # nothing here exercised it. So this one goes through the real call.
  it 'bounds the auth client, whose calls run on the singleton' do
    options = nil
    allow(HTTParty).to receive(:get) do |_url, **kwargs|
      options = kwargs
      instance_double(HTTParty::Response, success?: true, body: { code: 0, data: {} }.to_json)
    end

    Tiktok::AuthClient.webhook_callback

    expect(options).to include(timeout: 10, max_retries: 0)
  end

  # A fence, not a checklist. One ceiling for the eight HTTParty calls, so the count of
  # calls and the count of ceilings have to match; the Faraday one is named separately
  # above because it is a different mechanism with a different failure.
  it 'puts every TikTok call under the ceiling' do
    sources = %w[
      app/services/tiktok/client.rb
      app/services/tiktok/auth_client.rb
    ].map { |path| File.read(Rails.root.join(path)) }.join

    expect(sources.scan(/HTTParty\.\w+/).size).to eq(8)
    expect(sources.scan('TIKTOK_REQUEST_OPTIONS').size).to eq(8)
    expect(sources.scan('Faraday.new').size).to eq(1)
  end
end

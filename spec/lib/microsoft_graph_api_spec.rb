require 'rails_helper'
# explicitly requiring since we are loading apms conditionally in application.rb
require 'sentry-ruby'

describe MicrosoftGraphApi do
  let(:yesterday) { (Time.zone.today - 1).strftime('%FT%TZ') }
  let(:tomorrow) { (Time.zone.today + 1).strftime('%FT%TZ') }

  describe '#get_from_api' do
    before do
      stub_request(:get, "https://graph.microsoft.com/v1.0/me/messages?$filter=receivedDateTime%20ge%20#{yesterday}%20and%20receivedDateTime%20le%20#{tomorrow}&$select=id&$top=1000")
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'Bearer access_token',
            'User-Agent' => 'Ruby'
          }
        )
        .to_return(status: 200, body: '{"value":[{"id":"1"}]}', headers: {})

      stub_request(:get, 'https://graph.microsoft.com/v1.0/me/messages/1/$value')
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'Bearer access_token',
            'User-Agent' => 'Ruby'
          }
        )
        .to_return(status: 200, body: '', headers: {})

      stub_request(:post, 'https://graph.microsoft.com/v1.0/me/sendMail')
        .with(
          body: 'email body',
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'Bearer access_token',
            'User-Agent' => 'Ruby'
          }
        )
        .to_return(status: 200, body: 'email body', headers: { 'Content-Type' => 'text/plain' })
    end

    it 'fetch emails' do
      graph_query = { :$filter => "receivedDateTime ge #{yesterday} and receivedDateTime le #{tomorrow}", :$top => '1000', :$select => 'id' }
      response = described_class.new('access_token').get_from_api('me/messages', {}, graph_query)

      json_response = JSON.parse(response.body)
      expect(json_response['value'][0]['id']).to eq '1'
    end

    it 'post emails' do
      response = described_class.new('access_token').post_to_api('me/sendMail', {}, 'email body')

      expect(response.is_a?(Net::HTTPSuccess)).to be true
      expect(response.body).to eq('email body')
    end
  end
end

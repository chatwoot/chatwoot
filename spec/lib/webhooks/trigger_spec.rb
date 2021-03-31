require 'rails_helper'

describe Webhooks::Trigger do
  subject(:trigger) { described_class }

  describe '#execute' do
    it 'triggers webhook' do
      payload = { hello: :hello }
      url = 'https://test.com'

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: 5
        ).once
      trigger.execute(url, payload)
    end
  end
end

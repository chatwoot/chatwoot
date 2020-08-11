require 'rails_helper'

describe Webhooks::Trigger do
  subject(:trigger) { described_class }

  describe '#execute' do
    it 'triggers webhook' do
      params = { hello: :hello }
      url = 'https://test.com'

      expect(RestClient).to receive(:post).with(url, params.to_json, { accept: :json, content_type: :json }).once
      trigger.execute(url, params)
    end
  end
end

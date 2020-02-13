require 'rails_helper'

describe Webhooks::Trigger do
  subject(:trigger) { described_class }

  describe '#execute' do
    it 'triggers webhook' do
      params = { hello: 'hello' }
      url = 'htpps://test.com'

      expect(RestClient).to receive(:post).with(url, params).once
      trigger.execute(url, params)
    end
  end
end

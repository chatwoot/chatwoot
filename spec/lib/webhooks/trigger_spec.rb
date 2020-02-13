require 'rails_helper'

describe Webhooks::Trigger do
  subject(:trigger) { described_class }

  describe '#execute' do
    it 'triggers webhook' do
      params = { hello: 'hello' }
      url = 'htpps://test.com'

      expect(RestClient).to have_received(:post).with(url, params)
      trigger.execute(url, params)
    end
  end
end

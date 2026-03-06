# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    stub_request(:get, %r{\Ahttps://www\.google\.com/s2/favicons\?.*})
      .to_return(status: 404, body: '', headers: {})
  end
end

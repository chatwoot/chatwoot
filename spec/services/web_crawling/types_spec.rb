require 'rails_helper'

RSpec.describe WebCrawling::Types do
  it 'exposes immutable page values' do
    page = described_class::Page.new(url: 'https://example.com')

    expect { page.url = 'https://changed.example.com' }.to raise_error(NoMethodError)
  end
end

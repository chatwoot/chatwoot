require 'rails_helper'

RSpec.describe WebCrawling::Types do
  it 'exposes immutable page values' do
    page = described_class::Page.new(url: 'https://example.com')

    expect { page.url = 'https://changed.example.com' }.to raise_error(NoMethodError)
  end

  it 'keeps batch result pages immutable' do
    results = described_class::BatchResults.new(pages: [], has_more: false)

    expect { results.pages << described_class::Page.new(url: 'https://example.com') }.to raise_error(FrozenError)
  end
end

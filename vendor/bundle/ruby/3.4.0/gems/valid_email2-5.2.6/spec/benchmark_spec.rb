# frozen_string_literal: true

require "spec_helper"

describe "Performance testing" do
  let(:disposable_domain) { ValidEmail2.disposable_emails.first }

  it "has acceptable lookup performance" do
    address = ValidEmail2::Address.new("test@example.com")

    # preload list and check size
    expect(ValidEmail2.disposable_emails).to be_a(Set)
    expect(ValidEmail2.disposable_emails.count).to be > 30000

    # check lookup timing
    expect { address.disposable_domain? }.to perform_under(0.0001).sample(10).times
  end
end

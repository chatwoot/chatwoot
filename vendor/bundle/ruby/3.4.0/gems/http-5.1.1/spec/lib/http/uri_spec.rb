# frozen_string_literal: true

RSpec.describe HTTP::URI do
  let(:example_ipv6_address) { "2606:2800:220:1:248:1893:25c8:1946" }

  let(:example_http_uri_string)  { "http://example.com" }
  let(:example_https_uri_string) { "https://example.com" }
  let(:example_ipv6_uri_string) { "https://[#{example_ipv6_address}]" }

  subject(:http_uri)  { described_class.parse(example_http_uri_string) }
  subject(:https_uri) { described_class.parse(example_https_uri_string) }
  subject(:ipv6_uri) { described_class.parse(example_ipv6_uri_string) }

  it "knows URI schemes" do
    expect(http_uri.scheme).to eq "http"
    expect(https_uri.scheme).to eq "https"
  end

  it "sets default ports for HTTP URIs" do
    expect(http_uri.port).to eq 80
  end

  it "sets default ports for HTTPS URIs" do
    expect(https_uri.port).to eq 443
  end

  describe "#host" do
    it "strips brackets from IPv6 addresses" do
      expect(ipv6_uri.host).to eq("2606:2800:220:1:248:1893:25c8:1946")
    end
  end

  describe "#normalized_host" do
    it "strips brackets from IPv6 addresses" do
      expect(ipv6_uri.normalized_host).to eq("2606:2800:220:1:248:1893:25c8:1946")
    end
  end

  describe "#host=" do
    it "updates cached values for #host and #normalized_host" do
      expect(http_uri.host).to eq("example.com")
      expect(http_uri.normalized_host).to eq("example.com")

      http_uri.host = "[#{example_ipv6_address}]"

      expect(http_uri.host).to eq(example_ipv6_address)
      expect(http_uri.normalized_host).to eq(example_ipv6_address)
    end

    it "ensures IPv6 addresses are bracketed in the inner Addressable::URI" do
      expect(http_uri.host).to eq("example.com")
      expect(http_uri.normalized_host).to eq("example.com")

      http_uri.host = example_ipv6_address

      expect(http_uri.host).to eq(example_ipv6_address)
      expect(http_uri.normalized_host).to eq(example_ipv6_address)
      expect(http_uri.instance_variable_get(:@uri).host).to eq("[#{example_ipv6_address}]")
    end
  end

  describe "#dup" do
    it "doesn't share internal value between duplicates" do
      duplicated_uri = http_uri.dup
      duplicated_uri.host = "example.org"

      expect(duplicated_uri.to_s).to eq("http://example.org")
      expect(http_uri.to_s).to eq("http://example.com")
    end
  end
end

require_relative '_lib'

describe RestClient::AbstractResponse, :include_helpers do

  # Sample class implementing AbstractResponse used for testing.
  class MyAbstractResponse

    include RestClient::AbstractResponse

    attr_accessor :size

    def initialize(net_http_res, request)
      response_set_vars(net_http_res, request, Time.now - 1)
    end

  end

  before do
    @net_http_res = res_double()
    @request = request_double(url: 'http://example.com', method: 'get')
    @response = MyAbstractResponse.new(@net_http_res, @request)
  end

  it "fetches the numeric response code" do
    expect(@net_http_res).to receive(:code).and_return('200')
    expect(@response.code).to eq 200
  end

  it "has a nice description" do
    expect(@net_http_res).to receive(:to_hash).and_return({'Content-Type' => ['application/pdf']})
    expect(@net_http_res).to receive(:code).and_return('200')
    expect(@response.description).to eq "200 OK | application/pdf  bytes\n"
  end

  describe '.beautify_headers' do
    it "beautifies the headers by turning the keys to symbols" do
      h = RestClient::AbstractResponse.beautify_headers('content-type' => [ 'x' ])
      expect(h.keys.first).to eq :content_type
    end

    it "beautifies the headers by turning the values to strings instead of one-element arrays" do
      h = RestClient::AbstractResponse.beautify_headers('x' => [ 'text/html' ] )
      expect(h.values.first).to eq 'text/html'
    end

    it 'joins multiple header values by comma' do
      expect(RestClient::AbstractResponse.beautify_headers(
        {'My-Header' => ['one', 'two']}
      )).to eq({:my_header => 'one, two'})
    end

    it 'leaves set-cookie headers as array' do
      expect(RestClient::AbstractResponse.beautify_headers(
        {'Set-Cookie' => ['cookie1=foo', 'cookie2=bar']}
      )).to eq({:set_cookie => ['cookie1=foo', 'cookie2=bar']})
    end
  end

  it "fetches the headers" do
    expect(@net_http_res).to receive(:to_hash).and_return('content-type' => [ 'text/html' ])
    expect(@response.headers).to eq({ :content_type => 'text/html' })
  end

  it "extracts cookies from response headers" do
    expect(@net_http_res).to receive(:to_hash).and_return('set-cookie' => ['session_id=1; path=/'])
    expect(@response.cookies).to eq({ 'session_id' => '1' })
  end

  it "extract strange cookies" do
    expect(@net_http_res).to receive(:to_hash).and_return('set-cookie' => ['session_id=ZJ/HQVH6YE+rVkTpn0zvTQ==; path=/'])
    expect(@response.headers).to eq({:set_cookie => ['session_id=ZJ/HQVH6YE+rVkTpn0zvTQ==; path=/']})
    expect(@response.cookies).to eq({ 'session_id' => 'ZJ/HQVH6YE+rVkTpn0zvTQ==' })
  end

  it "doesn't escape cookies" do
    expect(@net_http_res).to receive(:to_hash).and_return('set-cookie' => ['session_id=BAh7BzoNYXBwX25hbWUiEGFwcGxpY2F0aW9uOgpsb2dpbiIKYWRtaW4%3D%0A--08114ba654f17c04d20dcc5228ec672508f738ca; path=/'])
    expect(@response.cookies).to eq({ 'session_id' => 'BAh7BzoNYXBwX25hbWUiEGFwcGxpY2F0aW9uOgpsb2dpbiIKYWRtaW4%3D%0A--08114ba654f17c04d20dcc5228ec672508f738ca' })
  end

  describe '.cookie_jar' do
    it 'extracts cookies into cookie jar' do
      expect(@net_http_res).to receive(:to_hash).and_return('set-cookie' => ['session_id=1; path=/'])
      expect(@response.cookie_jar).to be_a HTTP::CookieJar

      cookie = @response.cookie_jar.cookies.first
      expect(cookie.domain).to eq 'example.com'
      expect(cookie.name).to eq 'session_id'
      expect(cookie.value).to eq '1'
      expect(cookie.path).to eq '/'
    end

    it 'handles cookies when URI scheme is implicit' do
      net_http_res = double('net http response')
      expect(net_http_res).to receive(:to_hash).and_return('set-cookie' => ['session_id=1; path=/'])
      request = double('request', url: 'example.com', uri: URI.parse('http://example.com'),
                       method: 'get', cookie_jar: HTTP::CookieJar.new, redirection_history: nil)
      response = MyAbstractResponse.new(net_http_res, request)
      expect(response.cookie_jar).to be_a HTTP::CookieJar

      cookie = response.cookie_jar.cookies.first
      expect(cookie.domain).to eq 'example.com'
      expect(cookie.name).to eq 'session_id'
      expect(cookie.value).to eq '1'
      expect(cookie.path).to eq '/'
    end
  end

  it "can access the net http result directly" do
    expect(@response.net_http_res).to eq @net_http_res
  end

  describe "#return!" do
    it "should return the response itself on 200-codes" do
      expect(@net_http_res).to receive(:code).and_return('200')
      expect(@response.return!).to be_equal(@response)
    end

    it "should raise RequestFailed on unknown codes" do
      expect(@net_http_res).to receive(:code).and_return('1000')
      expect { @response.return! }.to raise_error RestClient::RequestFailed
    end

    it "should raise an error on a redirection after non-GET/HEAD requests" do
      expect(@net_http_res).to receive(:code).and_return('301')
      expect(@request).to receive(:method).and_return('put')
      expect(@response).not_to receive(:follow_redirection)
      expect { @response.return! }.to raise_error RestClient::RequestFailed
    end

    it "should follow 302 redirect" do
      expect(@net_http_res).to receive(:code).and_return('302')
      expect(@response).to receive(:check_max_redirects).and_return('fake-check')
      expect(@response).to receive(:follow_redirection).and_return('fake-redirection')
      expect(@response.return!).to eq 'fake-redirection'
    end

    it "should gracefully handle 302 redirect with no location header" do
      @net_http_res = res_double(code: 302)
      @request = request_double()
      @response = MyAbstractResponse.new(@net_http_res, @request)
      expect(@response).to receive(:check_max_redirects).and_return('fake-check')
      expect { @response.return! }.to raise_error RestClient::Found
    end
  end
end

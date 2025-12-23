require_relative '_lib'

describe RestClient::Response, :include_helpers do
  before do
    @net_http_res = res_double(to_hash: {'Status' => ['200 OK']}, code: '200', body: 'abc')
    @example_url = 'http://example.com'
    @request = request_double(url: @example_url, method: 'get')
    @response = response_from_res_double(@net_http_res, @request, duration: 1)
  end

  it "behaves like string" do
    expect(@response.to_s).to eq 'abc'
    expect(@response.to_str).to eq 'abc'

    expect(@response).to receive(:warn)
    expect(@response.to_i).to eq 0
  end

  it "accepts nil strings and sets it to empty for the case of HEAD" do
    # TODO
    expect(RestClient::Response.create(nil, @net_http_res, @request).to_s).to eq ""
  end

  describe 'header processing' do
    it "test headers and raw headers" do
      expect(@response.raw_headers["Status"][0]).to eq "200 OK"
      expect(@response.headers[:status]).to eq "200 OK"
    end

    it 'handles multiple headers by joining with comma' do
      net_http_res = res_double(to_hash: {'My-Header' => ['foo', 'bar']}, code: '200', body: nil)
      example_url = 'http://example.com'
      request = request_double(url: example_url, method: 'get')
      response = response_from_res_double(net_http_res, request)

      expect(response.raw_headers['My-Header']).to eq ['foo', 'bar']
      expect(response.headers[:my_header]).to eq 'foo, bar'
    end
  end

  describe "cookie processing" do
    it "should correctly deal with one Set-Cookie header with one cookie inside" do
      header_val = "main_page=main_page_no_rewrite; path=/; expires=Sat, 10-Jan-2037 15:03:14 GMT".freeze

      net_http_res = double('net http response', :to_hash => {"etag" => ["\"e1ac1a2df945942ef4cac8116366baad\""], "set-cookie" => [header_val]})
      response = RestClient::Response.create('abc', net_http_res, @request)
      expect(response.headers[:set_cookie]).to eq [header_val]
      expect(response.cookies).to eq({ "main_page" => "main_page_no_rewrite" })
    end

    it "should correctly deal with multiple cookies [multiple Set-Cookie headers]" do
      net_http_res = double('net http response', :to_hash => {"etag" => ["\"e1ac1a2df945942ef4cac8116366baad\""], "set-cookie" => ["main_page=main_page_no_rewrite; path=/; expires=Sat, 10-Jan-2037 15:03:14 GMT", "remember_me=; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT", "user=somebody; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT"]})
      response = RestClient::Response.create('abc', net_http_res, @request)
      expect(response.headers[:set_cookie]).to eq ["main_page=main_page_no_rewrite; path=/; expires=Sat, 10-Jan-2037 15:03:14 GMT", "remember_me=; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT", "user=somebody; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT"]
      expect(response.cookies).to eq({
        "main_page" => "main_page_no_rewrite",
        "remember_me" => "",
        "user" => "somebody"
      })
    end

    it "should correctly deal with multiple cookies [one Set-Cookie header with multiple cookies]" do
      net_http_res = double('net http response', :to_hash => {"etag" => ["\"e1ac1a2df945942ef4cac8116366baad\""], "set-cookie" => ["main_page=main_page_no_rewrite; path=/; expires=Sat, 10-Jan-2037 15:03:14 GMT, remember_me=; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT, user=somebody; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT"]})
      response = RestClient::Response.create('abc', net_http_res, @request)
      expect(response.cookies).to eq({
        "main_page" => "main_page_no_rewrite",
        "remember_me" => "",
        "user" => "somebody"
      })
    end
  end

  describe "exceptions processing" do
    it "should return itself for normal codes" do
      (200..206).each do |code|
        net_http_res = res_double(:code => '200')
        resp = RestClient::Response.create('abc', net_http_res, @request)
        resp.return!
      end
    end

    it "should throw an exception for other codes" do
      RestClient::Exceptions::EXCEPTIONS_MAP.each_pair do |code, exc|
        unless (200..207).include? code
          net_http_res = res_double(:code => code.to_i)
          resp = RestClient::Response.create('abc', net_http_res, @request)
          allow(@request).to receive(:max_redirects).and_return(5)
          expect { resp.return! }.to raise_error(exc)
        end
      end
    end

  end

  describe "redirection" do

    it "follows a redirection when the request is a get" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://new/resource'})
      stub_request(:get, 'http://new/resource').to_return(:body => 'Foo')
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body).to eq 'Foo'
    end

    it "keeps redirection history" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://new/resource'})
      stub_request(:get, 'http://new/resource').to_return(:body => 'Foo')
      r = RestClient::Request.execute(url: 'http://some/resource', method: :get)
      expect(r.body).to eq 'Foo'
      expect(r.history.length).to eq 1
      expect(r.history.fetch(0)).to be_a(RestClient::Response)
      expect(r.history.fetch(0).code).to be 301
    end

    it "follows a redirection and keep the parameters" do
      stub_request(:get, 'http://some/resource').with(:headers => {'Accept' => 'application/json'}, :basic_auth => ['foo', 'bar']).to_return(:body => '', :status => 301, :headers => {'Location' => 'http://new/resource'})
      stub_request(:get, 'http://new/resource').with(:headers => {'Accept' => 'application/json'}, :basic_auth => ['foo', 'bar']).to_return(:body => 'Foo')
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :get, :user => 'foo', :password => 'bar', :headers => {:accept => :json}).body).to eq 'Foo'
    end

    it "follows a redirection and keep the cookies" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Set-Cookie' => 'Foo=Bar', 'Location' => 'http://some/new_resource', })
      stub_request(:get, 'http://some/new_resource').with(:headers => {'Cookie' => 'Foo=Bar'}).to_return(:body => 'Qux')
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body).to eq 'Qux'
    end

    it 'respects cookie domains on redirect' do
      stub_request(:get, 'http://some.example.com/').to_return(:body => '', :status => 301,
        :headers => {'Set-Cookie' => 'Foo=Bar', 'Location' => 'http://new.example.com/', })
      stub_request(:get, 'http://new.example.com/').with(
        :headers => {'Cookie' => 'passedthrough=1'}).to_return(:body => 'Qux')

      expect(RestClient::Request.execute(:url => 'http://some.example.com/', :method => :get, cookies: [HTTP::Cookie.new('passedthrough', '1', domain: 'new.example.com', path: '/')]).body).to eq 'Qux'
    end

    it "doesn't follow a 301 when the request is a post" do
      net_http_res = res_double(:code => 301)
      response = response_from_res_double(net_http_res, request_double(method: 'post'))

      expect {
        response.return!
      }.to raise_error(RestClient::MovedPermanently)
    end

    it "doesn't follow a 302 when the request is a post" do
      net_http_res = res_double(:code => 302)
      response = response_from_res_double(net_http_res, request_double(method: 'post'))

      expect {
        response.return!
      }.to raise_error(RestClient::Found)
    end

    it "doesn't follow a 307 when the request is a post" do
      net_http_res = res_double(:code => 307)
      response = response_from_res_double(net_http_res, request_double(method: 'post'))

      expect(response).not_to receive(:follow_redirection)
      expect {
        response.return!
      }.to raise_error(RestClient::TemporaryRedirect)
    end

    it "doesn't follow a redirection when the request is a put" do
      net_http_res = res_double(:code => 301)
      response = response_from_res_double(net_http_res, request_double(method: 'put'))
      expect {
        response.return!
      }.to raise_error(RestClient::MovedPermanently)
    end

    it "follows a redirection when the request is a post and result is a 303" do
      stub_request(:put, 'http://some/resource').to_return(:body => '', :status => 303, :headers => {'Location' => 'http://new/resource'})
      stub_request(:get, 'http://new/resource').to_return(:body => 'Foo')
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :put).body).to eq 'Foo'
    end

    it "follows a redirection when the request is a head" do
      stub_request(:head, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://new/resource'})
      stub_request(:head, 'http://new/resource').to_return(:body => 'Foo')
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :head).body).to eq 'Foo'
    end

    it "handles redirects with relative paths" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'index'})
      stub_request(:get, 'http://some/index').to_return(:body => 'Foo')
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body).to eq 'Foo'
    end

    it "handles redirects with relative path and query string" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'index?q=1'})
      stub_request(:get, 'http://some/index?q=1').to_return(:body => 'Foo')
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body).to eq 'Foo'
    end

    it "follow a redirection when the request is a get and the response is in the 30x range" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://new/resource'})
      stub_request(:get, 'http://new/resource').to_return(:body => 'Foo')
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body).to eq 'Foo'
    end

    it "follows no more than 10 redirections before raising error" do
      stub_request(:get, 'http://some/redirect-1').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://some/redirect-2'})
      stub_request(:get, 'http://some/redirect-2').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://some/redirect-2'})
      expect {
        RestClient::Request.execute(url: 'http://some/redirect-1', method: :get)
      }.to raise_error(RestClient::MovedPermanently) { |ex|
        ex.response.history.each {|r| expect(r).to be_a(RestClient::Response) }
        expect(ex.response.history.length).to eq 10
      }
      expect(WebMock).to have_requested(:get, 'http://some/redirect-2').times(10)
    end

    it "follows no more than max_redirects redirections, if specified" do
      stub_request(:get, 'http://some/redirect-1').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://some/redirect-2'})
      stub_request(:get, 'http://some/redirect-2').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://some/redirect-2'})
      expect {
        RestClient::Request.execute(url: 'http://some/redirect-1', method: :get, max_redirects: 5)
      }.to raise_error(RestClient::MovedPermanently) { |ex|
        expect(ex.response.history.length).to eq 5
      }
      expect(WebMock).to have_requested(:get, 'http://some/redirect-2').times(5)
    end

    it "allows for manual following of redirects" do
      stub_request(:get, 'http://some/redirect-1').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://some/resource'})
      stub_request(:get, 'http://some/resource').to_return(:body => 'Qux', :status => 200)

      begin
        RestClient::Request.execute(url: 'http://some/redirect-1', method: :get, max_redirects: 0)
      rescue RestClient::MovedPermanently => err
        resp = err.response.follow_redirection
      else
        raise 'notreached'
      end

      expect(resp.code).to eq 200
      expect(resp.body).to eq 'Qux'
    end
  end

  describe "logging" do
    it "uses the request's logger" do
      stub_request(:get, 'http://some/resource').to_return(body: 'potato', status: 200)

      logger = double('logger', '<<' => true)
      request = RestClient::Request.new(url: 'http://some/resource', method: :get, log: logger)

      expect(logger).to receive(:<<)

      request.execute
    end
  end
end

# encoding: utf-8
# frozen_string_literal: true

require "json"

require "support/dummy_server"
require "support/proxy_server"

RSpec.describe HTTP do
  run_server(:dummy) { DummyServer.new }
  run_server(:dummy_ssl) { DummyServer.new(:ssl => true) }

  let(:ssl_client) do
    HTTP::Client.new :ssl_context => SSLHelper.client_context
  end

  context "getting resources" do
    it "is easy" do
      response = HTTP.get dummy.endpoint
      expect(response.to_s).to match(/<!doctype html>/)
    end

    context "with URI instance" do
      it "is easy" do
        response = HTTP.get HTTP::URI.parse dummy.endpoint
        expect(response.to_s).to match(/<!doctype html>/)
      end
    end

    context "with query string parameters" do
      it "is easy" do
        response = HTTP.get "#{dummy.endpoint}/params", :params => {:foo => "bar"}
        expect(response.to_s).to match(/Params!/)
      end
    end

    context "with query string parameters in the URI and opts hash" do
      it "includes both" do
        response = HTTP.get "#{dummy.endpoint}/multiple-params?foo=bar", :params => {:baz => "quux"}
        expect(response.to_s).to match(/More Params!/)
      end
    end

    context "with two leading slashes in path" do
      it "is allowed" do
        expect { HTTP.get "#{dummy.endpoint}//" }.not_to raise_error
      end
    end

    context "with headers" do
      it "is easy" do
        response = HTTP.accept("application/json").get dummy.endpoint
        expect(response.to_s.include?("json")).to be true
      end
    end

    context "with a large request body" do
      let(:request_body) { "“" * 1_000_000 } # use multi-byte character

      [:null, 6, {:read => 2, :write => 2, :connect => 2}].each do |timeout|
        context "with `.timeout(#{timeout.inspect})`" do
          let(:client) { HTTP.timeout(timeout) }

          it "writes the whole body" do
            response = client.post "#{dummy.endpoint}/echo-body", :body => request_body

            expect(response.body.to_s).to eq(request_body.b)
            expect(response.headers["Content-Length"].to_i).to eq request_body.bytesize
          end
        end
      end
    end
  end

  describe ".via" do
    context "anonymous proxy" do
      run_server(:proxy) { ProxyServer.new }

      it "proxies the request" do
        response = HTTP.via(proxy.addr, proxy.port).get dummy.endpoint
        expect(response.headers["X-Proxied"]).to eq "true"
      end

      it "responds with the endpoint's body" do
        response = HTTP.via(proxy.addr, proxy.port).get dummy.endpoint
        expect(response.to_s).to match(/<!doctype html>/)
      end

      it "raises an argument error if no port given" do
        expect { HTTP.via(proxy.addr) }.to raise_error HTTP::RequestError
      end

      it "ignores credentials" do
        response = HTTP.via(proxy.addr, proxy.port, "username", "password").get dummy.endpoint
        expect(response.to_s).to match(/<!doctype html>/)
      end

      # TODO: htt:s://github.com/httprb/http/issues/627
      xcontext "ssl" do
        it "responds with the endpoint's body" do
          response = ssl_client.via(proxy.addr, proxy.port).get dummy_ssl.endpoint
          expect(response.to_s).to match(/<!doctype html>/)
        end

        it "ignores credentials" do
          response = ssl_client.via(proxy.addr, proxy.port, "username", "password").get dummy_ssl.endpoint
          expect(response.to_s).to match(/<!doctype html>/)
        end
      end
    end

    context "proxy with authentication" do
      run_server(:proxy) { AuthProxyServer.new }

      it "proxies the request" do
        response = HTTP.via(proxy.addr, proxy.port, "username", "password").get dummy.endpoint
        expect(response.headers["X-Proxied"]).to eq "true"
      end

      it "responds with the endpoint's body" do
        response = HTTP.via(proxy.addr, proxy.port, "username", "password").get dummy.endpoint
        expect(response.to_s).to match(/<!doctype html>/)
      end

      it "responds with 407 when wrong credentials given" do
        response = HTTP.via(proxy.addr, proxy.port, "user", "pass").get dummy.endpoint
        expect(response.status).to eq(407)
      end

      it "responds with 407 if no credentials given" do
        response = HTTP.via(proxy.addr, proxy.port).get dummy.endpoint
        expect(response.status).to eq(407)
      end

      # TODO: htt:s://github.com/httprb/http/issues/627
      xcontext "ssl" do
        it "responds with the endpoint's body" do
          response = ssl_client.via(proxy.addr, proxy.port, "username", "password").get dummy_ssl.endpoint
          expect(response.to_s).to match(/<!doctype html>/)
        end

        it "responds with 407 when wrong credentials given" do
          response = ssl_client.via(proxy.addr, proxy.port, "user", "pass").get dummy_ssl.endpoint
          expect(response.status).to eq(407)
        end

        it "responds with 407 if no credentials given" do
          response = ssl_client.via(proxy.addr, proxy.port).get dummy_ssl.endpoint
          expect(response.status).to eq(407)
        end
      end
    end
  end

  context "posting forms to resources" do
    it "is easy" do
      response = HTTP.post "#{dummy.endpoint}/form", :form => {:example => "testing-form"}
      expect(response.to_s).to eq("passed :)")
    end
  end

  context "loading binary data" do
    it "is encoded as bytes" do
      response = HTTP.get "#{dummy.endpoint}/bytes"
      expect(response.to_s.encoding).to eq(Encoding::BINARY)
    end
  end

  context "loading endpoint with charset" do
    it "uses charset from headers" do
      response = HTTP.get "#{dummy.endpoint}/iso-8859-1"
      expect(response.to_s.encoding).to eq(Encoding::ISO8859_1)
      expect(response.to_s.encode(Encoding::UTF_8)).to eq("testæ")
    end

    context "with encoding option" do
      it "respects option" do
        response = HTTP.get "#{dummy.endpoint}/iso-8859-1", :encoding => Encoding::BINARY
        expect(response.to_s.encoding).to eq(Encoding::BINARY)
      end
    end
  end

  context "passing a string encoding type" do
    it "finds encoding" do
      response = HTTP.get dummy.endpoint, :encoding => "ascii"
      expect(response.to_s.encoding).to eq(Encoding::ASCII)
    end
  end

  context "loading text with no charset" do
    it "is binary encoded" do
      response = HTTP.get dummy.endpoint
      expect(response.to_s.encoding).to eq(Encoding::BINARY)
    end
  end

  context "posting with an explicit body" do
    it "is easy" do
      response = HTTP.post "#{dummy.endpoint}/body", :body => "testing-body"
      expect(response.to_s).to eq("passed :)")
    end
  end

  context "with redirects" do
    it "is easy for 301" do
      response = HTTP.follow.get("#{dummy.endpoint}/redirect-301")
      expect(response.to_s).to match(/<!doctype html>/)
    end

    it "is easy for 302" do
      response = HTTP.follow.get("#{dummy.endpoint}/redirect-302")
      expect(response.to_s).to match(/<!doctype html>/)
    end
  end

  context "head requests" do
    it "is easy" do
      response = HTTP.head dummy.endpoint
      expect(response.status).to eq(200)
      expect(response["content-type"]).to match(/html/)
    end
  end

  describe ".auth" do
    it "sets Authorization header to the given value" do
      client = HTTP.auth "abc"
      expect(client.default_options.headers[:authorization]).to eq "abc"
    end

    it "accepts any #to_s object" do
      client = HTTP.auth double :to_s => "abc"
      expect(client.default_options.headers[:authorization]).to eq "abc"
    end
  end

  describe ".basic_auth" do
    it "fails when options is not a Hash" do
      expect { HTTP.basic_auth "[FOOBAR]" }.to raise_error(NoMethodError)
    end

    it "fails when :pass is not given" do
      expect { HTTP.basic_auth :user => "[USER]" }.to raise_error(KeyError)
    end

    it "fails when :user is not given" do
      expect { HTTP.basic_auth :pass => "[PASS]" }.to raise_error(KeyError)
    end

    it "sets Authorization header with proper BasicAuth value" do
      client = HTTP.basic_auth :user => "foo", :pass => "bar"
      expect(client.default_options.headers[:authorization]).
        to match(%r{^Basic [A-Za-z0-9+/]+=*$})
    end
  end

  describe ".persistent" do
    let(:host) { "https://api.github.com" }

    context "with host only given" do
      subject { HTTP.persistent host }
      it { is_expected.to be_an HTTP::Client }
      it { is_expected.to be_persistent }
    end

    context "with host and block given" do
      it "returns last evaluation of last expression" do
        expect(HTTP.persistent(host) { :http }).to be :http
      end

      it "auto-closes connection" do
        HTTP.persistent host do |client|
          expect(client).to receive(:close).and_call_original
          client.get("/repos/httprb/http.rb")
        end
      end
    end

    context "with timeout specified" do
      subject(:client) { HTTP.persistent host, :timeout => 100 }
      it "sets keep_alive_timeout" do
        options = client.default_options
        expect(options.keep_alive_timeout).to eq(100)
      end
    end
  end

  describe ".timeout" do
    context "specifying a null timeout" do
      subject(:client) { HTTP.timeout :null }

      it "sets timeout_class to Null" do
        expect(client.default_options.timeout_class).
          to be HTTP::Timeout::Null
      end
    end

    context "specifying per operation timeouts" do
      subject(:client) { HTTP.timeout :read => 123 }

      it "sets timeout_class to PerOperation" do
        expect(client.default_options.timeout_class).
          to be HTTP::Timeout::PerOperation
      end

      it "sets given timeout options" do
        expect(client.default_options.timeout_options).
          to eq :read_timeout => 123
      end
    end

    context "specifying per operation timeouts as frozen hash" do
      let(:frozen_options) { {:read => 123}.freeze }
      subject(:client) { HTTP.timeout(frozen_options) }

      it "does not raise an error" do
        expect { client }.not_to raise_error
      end
    end

    context "specifying a global timeout" do
      subject(:client) { HTTP.timeout 123 }

      it "sets timeout_class to Global" do
        expect(client.default_options.timeout_class).
          to be HTTP::Timeout::Global
      end

      it "sets given timeout option" do
        expect(client.default_options.timeout_options).
          to eq :global_timeout => 123
      end
    end
  end

  describe ".cookies" do
    let(:endpoint) { "#{dummy.endpoint}/cookies" }

    it "passes correct `Cookie` header" do
      expect(HTTP.cookies(:abc => :def).get(endpoint).to_s).
        to eq "abc: def"
    end

    it "properly works with cookie jars from response" do
      res = HTTP.get(endpoint).flush

      expect(HTTP.cookies(res.cookies).get(endpoint).to_s).
        to eq "foo: bar"
    end

    it "properly merges cookies" do
      res     = HTTP.get(endpoint).flush
      client  = HTTP.cookies(:foo => 123, :bar => 321).cookies(res.cookies)

      expect(client.get(endpoint).to_s).to eq "foo: bar\nbar: 321"
    end

    it "properly merges Cookie headers and cookies" do
      client = HTTP.headers("Cookie" => "foo=bar").cookies(:baz => :moo)
      expect(client.get(endpoint).to_s).to eq "foo: bar\nbaz: moo"
    end
  end

  describe ".nodelay" do
    before do
      HTTP.default_options = {:socket_class => socket_spy_class}
    end

    after do
      HTTP.default_options = {}
    end

    let(:socket_spy_class) do
      Class.new(TCPSocket) do
        def self.setsockopt_calls
          @setsockopt_calls ||= []
        end

        def setsockopt(*args)
          self.class.setsockopt_calls << args
          super
        end
      end
    end

    it "sets TCP_NODELAY on the underlying socket" do
      HTTP.get(dummy.endpoint)
      expect(socket_spy_class.setsockopt_calls).to eq([])
      HTTP.nodelay.get(dummy.endpoint)
      expect(socket_spy_class.setsockopt_calls).to eq([[Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1]])
    end
  end

  describe ".use" do
    it "turns on given feature" do
      client = HTTP.use :auto_deflate
      expect(client.default_options.features.keys).to eq [:auto_deflate]
    end

    context "with :auto_deflate" do
      it "sends gzipped body" do
        client   = HTTP.use :auto_deflate
        body     = "Hello!"
        response = client.post("#{dummy.endpoint}/echo-body", :body => body)
        encoded  = response.to_s

        expect(Zlib::GzipReader.new(StringIO.new(encoded)).read).to eq body
      end

      it "sends deflated body" do
        client   = HTTP.use :auto_deflate => {:method => "deflate"}
        body     = "Hello!"
        response = client.post("#{dummy.endpoint}/echo-body", :body => body)
        encoded  = response.to_s

        expect(Zlib::Inflate.inflate(encoded)).to eq body
      end
    end

    context "with :auto_inflate" do
      it "returns raw body when Content-Encoding type is missing" do
        client   = HTTP.use :auto_inflate
        body     = "Hello!"
        response = client.post("#{dummy.endpoint}/encoded-body", :body => body)
        expect(response.to_s).to eq("#{body}-raw")
      end

      it "returns decoded body" do
        client   = HTTP.use(:auto_inflate).headers("Accept-Encoding" => "gzip")
        body     = "Hello!"
        response = client.post("#{dummy.endpoint}/encoded-body", :body => body)

        expect(response.to_s).to eq("#{body}-gzipped")
      end

      it "returns deflated body" do
        client   = HTTP.use(:auto_inflate).headers("Accept-Encoding" => "deflate")
        body     = "Hello!"
        response = client.post("#{dummy.endpoint}/encoded-body", :body => body)

        expect(response.to_s).to eq("#{body}-deflated")
      end

      it "returns empty body for no content response where Content-Encoding is gzip" do
        client   = HTTP.use(:auto_inflate).headers("Accept-Encoding" => "gzip")
        body     = "Hello!"
        response = client.post("#{dummy.endpoint}/no-content-204", :body => body)

        expect(response.to_s).to eq("")
      end

      it "returns empty body for no content response where Content-Encoding is deflate" do
        client   = HTTP.use(:auto_inflate).headers("Accept-Encoding" => "deflate")
        body     = "Hello!"
        response = client.post("#{dummy.endpoint}/no-content-204", :body => body)

        expect(response.to_s).to eq("")
      end
    end

    context "with :normalize_uri" do
      it "normalizes URI" do
        response = HTTP.get "#{dummy.endpoint}/hello world"
        expect(response.to_s).to eq("hello world")
      end

      it "uses the custom URI Normalizer method" do
        client = HTTP.use(:normalize_uri => {:normalizer => :itself.to_proc})
        response = client.get("#{dummy.endpoint}/hello world")
        expect(response.status).to eq(400)
      end

      it "uses the default URI normalizer" do
        client = HTTP.use :normalize_uri
        expect(HTTP::URI::NORMALIZER).to receive(:call).and_call_original
        response = client.get("#{dummy.endpoint}/hello world")
        expect(response.to_s).to eq("hello world")
      end
    end
  end

  it "unifies socket errors into HTTP::ConnectionError" do
    expect { HTTP.get "http://thishostshouldnotexists.com" }.
      to raise_error HTTP::ConnectionError

    expect { HTTP.get "http://127.0.0.1:111" }.
      to raise_error HTTP::ConnectionError
  end
end

require_relative '_lib'

describe RestClient::Request do
  before(:all) do
    WebMock.disable!
  end

  after(:all) do
    WebMock.enable!
  end

  describe "ssl verification" do
    it "is successful with the correct ca_file" do
      request = RestClient::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :ssl_ca_file => File.join(File.dirname(__FILE__), "certs", "digicert.crt")
      )
      expect { request.execute }.to_not raise_error
    end

    it "is successful with the correct ca_path" do
      request = RestClient::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :ssl_ca_path => File.join(File.dirname(__FILE__), "capath_digicert")
      )
      expect { request.execute }.to_not raise_error
    end

    # TODO: deprecate and remove RestClient::SSLCertificateNotVerified and just
    # pass through OpenSSL::SSL::SSLError directly. See note in
    # lib/restclient/request.rb.
    #
    # On OS X, this test fails since Apple has patched OpenSSL to always fall
    # back on the system CA store.
    it "is unsuccessful with an incorrect ca_file", :unless => RestClient::Platform.mac_mri? do
      request = RestClient::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :ssl_ca_file => File.join(File.dirname(__FILE__), "certs", "verisign.crt")
      )
      expect { request.execute }.to raise_error(RestClient::SSLCertificateNotVerified)
    end

    # On OS X, this test fails since Apple has patched OpenSSL to always fall
    # back on the system CA store.
    it "is unsuccessful with an incorrect ca_path", :unless => RestClient::Platform.mac_mri? do
      request = RestClient::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :ssl_ca_path => File.join(File.dirname(__FILE__), "capath_verisign")
      )
      expect { request.execute }.to raise_error(RestClient::SSLCertificateNotVerified)
    end

    it "is successful using the default system cert store" do
      request = RestClient::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :verify_ssl => true,
      )
      expect {request.execute }.to_not raise_error
    end

    it "executes the verify_callback" do
      ran_callback = false
      request = RestClient::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :verify_ssl => true,
        :ssl_verify_callback => lambda { |preverify_ok, store_ctx|
          ran_callback = true
          preverify_ok
        },
      )
      expect {request.execute }.to_not raise_error
      expect(ran_callback).to eq(true)
    end

    it "fails verification when the callback returns false",
       :unless => RestClient::Platform.mac_mri? do
      request = RestClient::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :verify_ssl => true,
        :ssl_verify_callback => lambda { |preverify_ok, store_ctx| false },
      )
      expect { request.execute }.to raise_error(RestClient::SSLCertificateNotVerified)
    end

    it "succeeds verification when the callback returns true",
       :unless => RestClient::Platform.mac_mri? do
      request = RestClient::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :verify_ssl => true,
        :ssl_ca_file => File.join(File.dirname(__FILE__), "certs", "verisign.crt"),
        :ssl_verify_callback => lambda { |preverify_ok, store_ctx| true },
      )
      expect { request.execute }.to_not raise_error
    end
  end

  describe "timeouts" do
    it "raises OpenTimeout when it hits an open timeout" do
      request = RestClient::Request.new(
        :method => :get,
        :url => 'http://www.mozilla.org',
        :open_timeout => 1e-10,
      )
      expect { request.execute }.to(
        raise_error(RestClient::Exceptions::OpenTimeout))
    end

    it "raises ReadTimeout when it hits a read timeout via :read_timeout" do
      request = RestClient::Request.new(
        :method => :get,
        :url => 'https://www.mozilla.org',
        :read_timeout => 1e-10,
      )
      expect { request.execute }.to(
        raise_error(RestClient::Exceptions::ReadTimeout))
    end
  end

end

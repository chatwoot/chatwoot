require_relative '_lib'

describe RestClient do
  describe "API" do
    it "GET" do
      expect(RestClient::Request).to receive(:execute).with(:method => :get, :url => 'http://some/resource', :headers => {})
      RestClient.get('http://some/resource')
    end

    it "POST" do
      expect(RestClient::Request).to receive(:execute).with(:method => :post, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      RestClient.post('http://some/resource', 'payload')
    end

    it "PUT" do
      expect(RestClient::Request).to receive(:execute).with(:method => :put, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      RestClient.put('http://some/resource', 'payload')
    end

    it "PATCH" do
      expect(RestClient::Request).to receive(:execute).with(:method => :patch, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      RestClient.patch('http://some/resource', 'payload')
    end

    it "DELETE" do
      expect(RestClient::Request).to receive(:execute).with(:method => :delete, :url => 'http://some/resource', :headers => {})
      RestClient.delete('http://some/resource')
    end

    it "HEAD" do
      expect(RestClient::Request).to receive(:execute).with(:method => :head, :url => 'http://some/resource', :headers => {})
      RestClient.head('http://some/resource')
    end

    it "OPTIONS" do
      expect(RestClient::Request).to receive(:execute).with(:method => :options, :url => 'http://some/resource', :headers => {})
      RestClient.options('http://some/resource')
    end
  end

  describe "logging" do
    after do
      RestClient.log = nil
    end

    it "uses << if the log is not a string" do
      log = RestClient.log = []
      expect(log).to receive(:<<).with('xyz')
      RestClient.log << 'xyz'
    end

    it "displays the log to stdout" do
      RestClient.log = 'stdout'
      expect(STDOUT).to receive(:puts).with('xyz')
      RestClient.log << 'xyz'
    end

    it "displays the log to stderr" do
      RestClient.log = 'stderr'
      expect(STDERR).to receive(:puts).with('xyz')
      RestClient.log << 'xyz'
    end

    it "append the log to the requested filename" do
      RestClient.log = '/tmp/restclient.log'
      f = double('file handle')
      expect(File).to receive(:open).with('/tmp/restclient.log', 'a').and_yield(f)
      expect(f).to receive(:puts).with('xyz')
      RestClient.log << 'xyz'
    end
  end

  describe 'version' do
    # test that there is a sane version number to avoid accidental 0.0.0 again
    it 'has a version > 2.0.0.alpha, < 3.0' do
      ver = Gem::Version.new(RestClient.version)
      expect(Gem::Requirement.new('> 2.0.0.alpha', '< 3.0')).to be_satisfied_by(ver)
    end
  end
end

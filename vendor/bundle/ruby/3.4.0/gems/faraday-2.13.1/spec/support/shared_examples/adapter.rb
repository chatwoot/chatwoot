# frozen_string_literal: true

shared_examples 'an adapter' do |**options|
  before { skip } if options[:skip]

  context 'with SSL enabled' do
    before { ENV['SSL'] = 'yes' }
    include_examples 'adapter examples', options
  end

  context 'with SSL disabled' do
    before { ENV['SSL'] = 'no' }
    include_examples 'adapter examples', options
  end
end

shared_examples 'adapter examples' do |**options|
  include Faraday::StreamingResponseChecker

  let(:adapter) { described_class.name.split('::').last }

  let(:conn_options) { { headers: { 'X-Faraday-Adapter' => adapter } }.merge(options[:conn_options] || {}) }

  let(:adapter_options) do
    return [] unless options[:adapter_options]

    if options[:adapter_options].is_a?(Array)
      options[:adapter_options]
    else
      [options[:adapter_options]]
    end
  end

  let(:protocol) { ssl_mode? ? 'https' : 'http' }
  let(:remote) { "#{protocol}://example.com" }
  let(:stub_remote) { remote }

  let(:conn) do
    conn_options[:ssl] ||= {}
    conn_options[:ssl][:ca_file] ||= ENV.fetch('SSL_FILE', nil)
    conn_options[:ssl][:verify_hostname] ||= ENV['SSL_VERIFY_HOSTNAME'] == 'yes'

    Faraday.new(remote, conn_options) do |conn|
      conn.request :url_encoded
      conn.response :raise_error
      conn.adapter described_class, *adapter_options
    end
  end

  let!(:request_stub) { stub_request(http_method, stub_remote) }

  after do
    expect(request_stub).to have_been_requested unless request_stub.disabled?
  end

  describe '#delete' do
    let(:http_method) { :delete }

    it_behaves_like 'a request method', :delete
  end

  describe '#get' do
    let(:http_method) { :get }

    it_behaves_like 'a request method', :get
  end

  describe '#head' do
    let(:http_method) { :head }

    it_behaves_like 'a request method', :head
  end

  describe '#options' do
    let(:http_method) { :options }

    it_behaves_like 'a request method', :options
  end

  describe '#patch' do
    let(:http_method) { :patch }

    it_behaves_like 'a request method', :patch
  end

  describe '#post' do
    let(:http_method) { :post }

    it_behaves_like 'a request method', :post
  end

  describe '#put' do
    let(:http_method) { :put }

    it_behaves_like 'a request method', :put
  end

  on_feature :trace_method do
    describe '#trace' do
      let(:http_method) { :trace }

      it_behaves_like 'a request method', :trace
    end
  end
end

require 'spec_helper'

describe Koala::HTTPService do
  it "has a faraday_middleware accessor" do
    expect(Koala::HTTPService.methods.map(&:to_sym)).to include(:faraday_middleware)
    expect(Koala::HTTPService.methods.map(&:to_sym)).to include(:faraday_middleware=)
  end

  it "has an http_options accessor" do
    expect(Koala::HTTPService).to respond_to(:http_options)
    expect(Koala::HTTPService).to respond_to(:http_options=)
  end

  it "sets http_options to {} by default" do
    expect(Koala::HTTPService.http_options).to eq({})
  end

  describe "DEFAULT_MIDDLEWARE" do
    class FakeBuilder
      attr_reader :requests, :uses, :adapters

      def use(arg)
        @uses ||= []
        @uses << arg
      end

      def request(arg)
        @requests ||= []
        @requests << arg
      end

      def adapter(arg)
        @adapters ||= []
        @adapters << arg
      end
    end

    let(:builder) { FakeBuilder.new }

    it "adds the right default middleware" do
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(builder)
      expect(builder.requests).to eq([:multipart, :url_encoded])
      expect(builder.adapters).to eq([Faraday.default_adapter])
    end
  end

  describe Koala::HTTPService::DEFAULT_SERVERS do
    let(:defaults) { Koala::HTTPService::DEFAULT_SERVERS }

    it "defines the graph server" do
      expect(defaults[:graph_server]).to eq("graph.facebook.com")
    end

    it "defines the dialog host" do
      expect(defaults[:dialog_host]).to eq("www.facebook.com")
    end

    it "defines the path replacement regular expression" do
      expect(defaults[:host_path_matcher]).to eq(/\.facebook/)
    end

    it "defines the video server replacement for uploads" do
      expect(defaults[:video_replace]).to eq("-video.facebook")
    end

    it "defines the beta tier replacement" do
      expect(defaults[:beta_replace]).to eq(".beta.facebook")
    end
  end

  describe ".encode_params" do
    it "returns an empty string if param_hash evaluates to false" do
      expect(Koala::HTTPService.encode_params(nil)).to eq('')
    end

    it "converts values to JSON if the value is not a String" do
      not_a_string = {not_a_string: 2}

      args = {
        :arg => not_a_string,
      }

      result = Koala::HTTPService.encode_params(args)
      expect(result.split('&').find do |key_and_val|
        key_and_val.match("arg=#{CGI.escape not_a_string.to_json}")
      end).to be_truthy
    end

    it "escapes all values" do
      args = Hash[*(1..4).map {|i| [i.to_s, "Value #{i}($"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        expect(val).to eq(CGI.escape(args[key]))
      end
    end

    it "encodes parameters in alphabetical order" do
      args = {:b => '2', 'a' => '1'}

      result = Koala::HTTPService.encode_params(args)
      expect(result.split('&').map{|key_val| key_val.split('=')[0]}).to eq(['a', 'b'])
    end

    it "converts all keys to Strings" do
      args = Hash[*(1..4).map {|i| [i, "val#{i}"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        expect(key).to eq(args.find{|key_val_arr| key_val_arr.last == val}.first.to_s)
      end
    end
  end

  describe ".make_request" do
    let(:mock_body) { "a body" }
    let(:mock_headers_hash) { double(value: "headers hash") }
    let(:mock_http_response) { double("Faraday Response", status: 200, headers: mock_headers_hash, body: mock_body) }

    let(:verb) { "get" }
    let(:options) { {} }
    let(:args) { {"an" => :arg } }
    let(:request) { Koala::HTTPService::Request.new(path: "/foo", verb: verb, args: args, options: options) }

    shared_examples_for :making_a_request do
      before :each do
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(mock_http_response)
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(mock_http_response)
      end

      it "makes a Faraday request appropriately" do
        expect_any_instance_of(Faraday::Connection).to receive(verb) do |instance, path, post_params|
          expect(path).to eq(request.path)
          expect(post_params).to eq(request.post_args)
          expect(instance.params).to eq(request.options[:params])
          expect(instance.url_prefix).to eq(URI.parse(request.server))

          mock_http_response
        end

        Koala::HTTPService.make_request(request)
      end

      it "returns the right response" do
        response = Koala::HTTPService.make_request(request)
        expect(response.status).to eq(mock_http_response.status)
        expect(response.headers).to eq(mock_http_response.headers)
        expect(response.body).to eq(mock_http_response.body)

      end

      it "logs verb, url and params to debug" do
        log_message = "#{verb.upcase}: #{request.path} params: #{request.raw_args.inspect}"
        expect(Koala::Utils.logger).to receive(:debug).with("STARTED => #{log_message}")
        expect(Koala::Utils.logger).to receive(:debug).with("FINISHED => #{log_message}")

        Koala::HTTPService.make_request(request)
      end
    end

    context "for gets" do
      it_should_behave_like :making_a_request
    end

    # we don't need to test delete and put since those are translated into posts
    context "for posts" do
      let(:verb) { "post" }

      it_should_behave_like :making_a_request
    end

    context "for JSON requests" do
      let(:verb) { "post" }
      let(:options) { {format: :json} }

      it "makes a Faraday request appropriately" do
        expect_any_instance_of(Faraday::Connection).to receive(verb) do |instance, path, &block|
          faraday_request = Faraday::Request.new
          faraday_request.headers = {}
          block.call(faraday_request)
          expect(faraday_request.path).to eq(request.path)
          expect(faraday_request.body).to eq(request.post_args.to_json)
          expect(faraday_request.headers).to include("Content-Type" => "application/json")

          mock_http_response
        end

        Koala::HTTPService.make_request(request)
      end
    end

    it "uses the default builder block if HTTPService.faraday_middleware block is not defined" do
      block = Proc.new { |builder|
        builder.request :multipart
        builder.request :url_encoded
      }
      stub_const("Koala::HTTPService::DEFAULT_MIDDLEWARE", block)
      allow(Koala::HTTPService).to receive(:faraday_middleware).and_return(nil)

      expect_any_instance_of(Faraday::Connection).to receive(:get) do |instance|
        expect(instance.builder.handlers).to eq([
          Faraday::Multipart::Middleware,
          Faraday::Request::UrlEncoded,
        ])
        mock_http_response
      end

      Koala::HTTPService.make_request(request)
    end

    it "uses the defined HTTPService.faraday_middleware block if defined" do
      block = Proc.new { |builder|
        builder.request :multipart
        builder.request :url_encoded
      }
      expect(Koala::HTTPService).to receive(:faraday_middleware).and_return(block)

      expect_any_instance_of(Faraday::Connection).to receive(:get) do |instance|
        expect(instance.builder.handlers).to eq([
          Faraday::Multipart::Middleware,
          Faraday::Request::UrlEncoded,
        ])
        mock_http_response
      end

      Koala::HTTPService.make_request(request)
    end

    context 'log_tokens configuration' do
      let(:args) { { "an" => :arg, "access_token" => "myvisbleaccesstoken" } }

      before(:each) do
        allow_any_instance_of(Faraday::Connection).to receive(:get) { double(status: '200', body: 'ok', headers: {}) }
      end

      it 'logs tokens' do
        allow(Koala.config).to receive(:mask_tokens) { false }

        expect(Koala::Utils).to receive(:debug).with('STARTED => GET: /foo params: {"an"=>:arg, "access_token"=>"myvisbleaccesstoken"}')
        expect(Koala::Utils).to receive(:debug).with('FINISHED => GET: /foo params: {"an"=>:arg, "access_token"=>"myvisbleaccesstoken"}')

        Koala::HTTPService.make_request(request)
      end

      it 'doesnt log tokens' do
        allow(Koala.config).to receive(:mask_tokens) { true }

        expect(Koala::Utils).to receive(:debug).with('STARTED => GET: /foo params: {"an"=>:arg, "access_token"=>"myvisbleac*****token"}')
        expect(Koala::Utils).to receive(:debug).with('FINISHED => GET: /foo params: {"an"=>:arg, "access_token"=>"myvisbleac*****token"}')

        Koala::HTTPService.make_request(request)
      end

      it 'hides the token for the debug_token api endpoint' do
        request = Koala::HTTPService::Request.new(path: "/debug_token", verb: verb, args: { input_token: 'myvisibleaccesstoken', 'access_token' => 'myvisibleaccesstoken' }, options: options)

        allow(Koala.config).to receive(:mask_tokens) { true }

        expect(Koala::Utils).to receive(:debug).with('STARTED => GET: /debug_token params: {"input_token"=>"myvisiblea*****token", "access_token"=>"myvisiblea*****token"}')
        expect(Koala::Utils).to receive(:debug).with('FINISHED => GET: /debug_token params: {"input_token"=>"myvisiblea*****token", "access_token"=>"myvisiblea*****token"}')

        Koala::HTTPService.make_request(request)
      end
    end
  end
end

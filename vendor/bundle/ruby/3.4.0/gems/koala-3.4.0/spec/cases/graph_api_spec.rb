require 'spec_helper'

describe 'Koala::Facebook::GraphAPIMethods' do
  before do
    @api = Koala::Facebook::API.new(@token)
    # app API
    @app_id = KoalaTest.app_id
    @app_access_token = KoalaTest.app_access_token
    @app_api = Koala::Facebook::API.new(@app_access_token)
  end

  let(:dummy_response) { double("fake response", data: {}, status: 200, body: "", headers: {}) }

  describe 'post-processing for' do
    let(:result) { double("result") }
    let(:post_processing) { lambda {|arg| {"result" => result, "args" => arg} } }

    # Most API methods have the same signature, we test get_object representatively
    # and the other methods which do some post-processing locally
    context '#get_object' do
      it 'returns result of block' do
        allow(@api).to receive(:api).and_return(dummy_response)
        expect(@api.get_object('barackobama', &post_processing)["result"]).to eq(result)
      end

      it "doesn't add token to received arguments" do
        args = {}.freeze
        expect(Koala).to receive(:make_request).and_return(dummy_response)
        expect(@api.get_object('barackobama', args, &post_processing)["result"]).to eq(result)
      end
    end

    context '#get_picture' do
      it 'returns result of block' do
        result_url = "a url"
        allow(@api).to receive(:api).and_return(Koala::HTTPService::Response.new(200, {"data" => {"is_silhouette" => false, "url" => result_url}}.to_json, {}))
        expect(@api.get_picture('koppel', &post_processing)["result"]).to eq(result)
      end
    end

    context '#get_page_access_token' do
      it 'returns result of block' do
        token = Koala::MockHTTPService::APP_ACCESS_TOKEN
        allow(@api).to receive(:api).and_return(
          Koala::HTTPService::Response.new(200, {"access_token" => token}.to_json, {})
        )
        response = @api.get_page_access_token('facebook', &post_processing)
        expect(response["args"]).to eq(token)
        expect(response["result"]).to eq(result)
      end
    end
  end

  context '#graph_call' do
    describe "the appsecret_proof option" do
      let(:path) { '/path' }

      it "is enabled by default if an app secret is present" do
        api = Koala::Facebook::API.new(@token, "mysecret")
        expect(api).to receive(:api).with(path, {}, 'get', :appsecret_proof => true).and_return(dummy_response)
        api.graph_call(path)
      end

      it "can be disabled manually" do
        api = Koala::Facebook::API.new(@token, "mysecret")
        expect(api).to receive(:api).with(path, {}, 'get', hash_not_including(appsecret_proof: true)).and_return(dummy_response)
        api.graph_call(path, {}, "get", appsecret_proof: false)
      end

      it "isn't included if no app secret is present" do
        expect(@api).to receive(:api).with(path, {}, 'get', {}).and_return(dummy_response)
        @api.graph_call(path)
      end
    end
  end
end

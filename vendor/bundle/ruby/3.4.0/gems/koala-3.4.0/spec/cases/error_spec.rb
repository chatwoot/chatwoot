require 'spec_helper'

BUC_USAGE_JSON = "{\"123456789012345\":[{\"type\":\"messenger\",\"call_count\":1,\"total_cputime\":1,\"total_time\":1,\"estimated_time_to_regain_access\":0}]}"
ADA_USAGE_JSON = "{\"acc_id_util_pct\":9.67}"
APP_USAGE_JSON = "{\"call_count\":0,\"total_cputime\":0,\"total_time\":0}"

describe Koala::Facebook::APIError do
  it "is a Koala::KoalaError" do
    expect(Koala::Facebook::APIError.new(nil, nil)).to be_a(Koala::KoalaError)
  end

  [:fb_error_type, :fb_error_code, :fb_error_subcode, :fb_error_message, :fb_error_user_msg, :fb_error_user_title, :fb_error_trace_id, :fb_error_rev, :fb_error_debug, :http_status, :response_body].each do |accessor|
    it "has an accessor for #{accessor}" do
      expect(Koala::Facebook::APIError.instance_methods.map(&:to_sym)).to include(accessor)
      expect(Koala::Facebook::APIError.instance_methods.map(&:to_sym)).to include(:"#{accessor}=")
    end
  end

  it "sets http_status to the provided status" do
    error_response = '{ "error": {"type": "foo", "other_details": "bar"} }'
    expect(Koala::Facebook::APIError.new(400, error_response).response_body).to eq(error_response)
  end

  it "sets response_body to the provided response body" do
    expect(Koala::Facebook::APIError.new(400, '').http_status).to eq(400)
  end

  context "with an error_info hash" do
    let(:error) {
      error_info = {
        'type' => 'type',
        'message' => 'message',
        'code' => 1,
        'error_subcode' => 'subcode',
        'error_user_msg' => 'error user message',
        'error_user_title' => 'error user title',
        'x-fb-trace-id' => 'fb trace id',
        'x-fb-debug' => 'fb debug token',
        'x-fb-rev' => 'fb revision',
        'x-business-use-case-usage' => BUC_USAGE_JSON,
        'x-ad-account-usage' => ADA_USAGE_JSON,
        'x-app-usage' => APP_USAGE_JSON
      }
      Koala::Facebook::APIError.new(400, '', error_info)
    }

    {
      :fb_error_type => 'type',
      :fb_error_message => 'message',
      :fb_error_code => 1,
      :fb_error_subcode => 'subcode',
      :fb_error_user_msg => 'error user message',
      :fb_error_user_title => 'error user title',
      :fb_error_trace_id => 'fb trace id',
      :fb_error_debug => 'fb debug token',
      :fb_error_rev => 'fb revision',
      :fb_buc_usage => JSON.parse(BUC_USAGE_JSON),
      :fb_ada_usage => JSON.parse(ADA_USAGE_JSON),
      :fb_app_usage => JSON.parse(APP_USAGE_JSON)
    }.each_pair do |accessor, value|
      it "sets #{accessor} to #{value}" do
        expect(error.send(accessor)).to eq(value)
      end
    end

    it "sets the error message appropriately" do
      expect(error.message).to eq("type: type, code: 1, error_subcode: subcode, message: message, error_user_title: error user title, error_user_msg: error user message, x-fb-trace-id: fb trace id [HTTP 400]")
    end
  end

  context "with an error_info string" do
    it "sets the error message \"error_info [HTTP http_status]\"" do
      error_info = "Facebook is down."
      error = Koala::Facebook::APIError.new(400, '', error_info)
      expect(error.message).to eq("Facebook is down. [HTTP 400]")
    end
  end

  context "with no error_info and a response_body containing error JSON" do
    it "should extract the error info from the response body" do
      response_body = '{ "error": { "type": "type", "message": "message", "code": 1, "error_subcode": "subcode", "error_user_msg": "error user message", "error_user_title": "error user title" } }'
      error = Koala::Facebook::APIError.new(400, response_body)
      {
        :fb_error_type => 'type',
        :fb_error_message => 'message',
        :fb_error_code => 1,
        :fb_error_subcode => 'subcode',
        :fb_error_user_msg => 'error user message',
        :fb_error_user_title => 'error user title',
        :fb_buc_usage => nil,
        :fb_ada_usage => nil,
        :fb_app_usage => nil
      }.each_pair do |accessor, value|
        expect(error.send(accessor)).to eq(value)
      end
    end
  end

end

describe Koala::KoalaError do
  it "is a StandardError" do
     expect(Koala::KoalaError.new).to be_a(StandardError)
  end
end

describe Koala::Facebook::OAuthSignatureError do
  it "is a Koala::KoalaError" do
     expect(Koala::KoalaError.new).to be_a(Koala::KoalaError)
  end
end

describe Koala::Facebook::BadFacebookResponse do
  it "is a Koala::Facebook::APIError" do
     expect(Koala::Facebook::BadFacebookResponse.new(nil, nil)).to be_a(Koala::Facebook::APIError)
  end
end

describe Koala::Facebook::OAuthTokenRequestError do
  it "is a Koala::Facebook::APIError" do
     expect(Koala::Facebook::OAuthTokenRequestError.new(nil, nil)).to be_a(Koala::Facebook::APIError)
  end
end

describe Koala::Facebook::ServerError do
  it "is a Koala::Facebook::APIError" do
     expect(Koala::Facebook::ServerError.new(nil, nil)).to be_a(Koala::Facebook::APIError)
  end
end

describe Koala::Facebook::ClientError do
  it "is a Koala::Facebook::APIError" do
     expect(Koala::Facebook::ClientError.new(nil, nil)).to be_a(Koala::Facebook::APIError)
  end
end

describe Koala::Facebook::AuthenticationError do
  it "is a Koala::Facebook::ClientError" do
     expect(Koala::Facebook::AuthenticationError.new(nil, nil)).to be_a(Koala::Facebook::ClientError)
  end
end

require 'spec_helper'

module Koala
  RSpec.describe "requests using GraphCollections" do
    let(:api) { Facebook::API.new(KoalaTest.app_access_token) }

    before :each do
      # use the right version of the API as of the writing of this test
      Koala.config.api_version = "v2.8"
    end

    it "can access the next page of a test accounts" do
      # NOTE: if recording this cassette again, you'll need to swap in the real access token. It's
      # been manually edited out of the cassette. (Once all tests are switched to VCR this will be
      # resolved.)
      KoalaTest.with_vcr_unless_live("app test accounts") do
        result = api.get_connection(KoalaTest.app_id, "accounts")
        expect(result).not_to be_empty
        expect(result.next_page).not_to be_empty
      end
    end
  end
end


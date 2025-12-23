require 'spec_helper'

describe "Koala::Facebook::OAuth" do
  before :all do
    # make the relevant test data easily accessible
    @app_id = KoalaTest.app_id
    @secret = KoalaTest.secret
    @code = KoalaTest.code
    @callback_url = KoalaTest.oauth_test_data["callback_url"]
    @access_token = KoalaTest.oauth_test_data["access_token"]
    @raw_token_string = KoalaTest.oauth_test_data["raw_token_string"]
    @raw_offline_access_token_string = KoalaTest.oauth_test_data["raw_offline_access_token_string"]

    # for signed requests (http://developers.facebook.com/docs/authentication/canvas/encryption_proposal)
    @signed_params = KoalaTest.oauth_test_data["signed_params"]
    @signed_params_result = KoalaTest.oauth_test_data["signed_params_result"]

    # this should expanded to cover all variables
    raise Exception, "Must supply app data to run FacebookOAuthTests!" unless @app_id && @secret && @callback_url &&
      @raw_token_string &&
      @raw_offline_access_token_string

    # we can just test against the same key twice
    @multiple_session_keys = [KoalaTest.session_key, KoalaTest.session_key] if KoalaTest.session_key

    @oauth = Koala::Facebook::OAuth.new(@app_id, @secret, @callback_url)
  end

  before :each do
    @time = Time.now
    allow(Time).to receive(:now).and_return(@time)
    allow(@time).to receive(:to_i).and_return(1273363199)
  end

  describe ".new" do
    it "properly initializes" do
      expect(@oauth).to be_truthy
    end

    it "properly sets attributes" do
      expect(@oauth.app_id == @app_id &&
             @oauth.app_secret == @secret &&
             @oauth.oauth_callback_url == @callback_url).to be_truthy
    end

    it "properly initializes without a callback_url" do
      @oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
    end

    it "properly sets attributes without a callback URL" do
      @oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
      expect(@oauth.app_id == @app_id &&
             @oauth.app_secret == @secret &&
             @oauth.oauth_callback_url == nil).to be_truthy
    end

    context "with global defaults" do
      let(:app_id) { :app_id }
      let(:app_secret) { :app_secret }
      let(:oauth_callback_url) { :oauth_callback_url }

      before :each do
        Koala.configure do |config|
          config.app_id = app_id
          config.app_secret = app_secret
          config.oauth_callback_url = oauth_callback_url
        end
      end

      it "defaults to the configured data if not otherwise provided" do
        oauth = Koala::Facebook::OAuth.new
        expect(oauth.app_id).to eq(app_id)
        expect(oauth.app_secret).to eq(app_secret)
        expect(oauth.oauth_callback_url).to eq(oauth_callback_url)
      end

      it "lets you override app_id" do
        other_value = :another_id
        oauth = Koala::Facebook::OAuth.new(other_value)
        expect(oauth.app_id).to eq(other_value)
      end

      it "lets you override secret" do
        other_value = :another_secret
        oauth = Koala::Facebook::OAuth.new(nil, other_value)
        expect(oauth.app_secret).to eq(other_value)
      end

      it "lets you override app_id" do
        other_value = :another_token
        oauth = Koala::Facebook::OAuth.new(nil, nil, other_value)
        expect(oauth.oauth_callback_url).to eq(other_value)
      end
    end
  end

  describe "for cookie parsing" do
    describe "get_user_info_from_cookies" do
      context "for signed cookies" do
        before :each do
          # we don't actually want to make requests to Facebook to redeem the code
          @cookie = KoalaTest.oauth_test_data["valid_signed_cookies"]
          @token = "my token"
          allow(@oauth).to receive(:get_access_token_info).and_return("access_token" => @token)
        end

        it "parses valid cookies" do
          result = @oauth.get_user_info_from_cookies(@cookie)
          expect(result).to be_a(Hash)
        end

        it "returns all the components in the signed request" do
          result = @oauth.get_user_info_from_cookies(@cookie)
          @oauth.parse_signed_request(@cookie.values.first).each_pair do |k, v|
            expect(result[k]).to eq(v)
          end
        end

        it "makes a request to Facebook to redeem the code if present" do
          code = "foo"
          allow(@oauth).to receive(:parse_signed_request).and_return({"code" => code})
          expect(@oauth).to receive(:get_access_token_info).with(code, anything)
          @oauth.get_user_info_from_cookies(@cookie)
        end

        it "sets the code redemption redirect_uri to ''" do
          expect(@oauth).to receive(:get_access_token_info).with(anything, :redirect_uri => '')
          @oauth.get_user_info_from_cookies(@cookie)
        end

        context "if the code is missing" do
          it "doesn't make a request to Facebook" do
            allow(@oauth).to receive(:parse_signed_request).and_return({})
            expect(@oauth).to receive(:get_access_token_info).never
            @oauth.get_user_info_from_cookies(@cookie)
          end

          it "returns nil" do
            allow(@oauth).to receive(:parse_signed_request).and_return({})
            expect(@oauth.get_user_info_from_cookies(@cookie)).to be_nil
          end

          it "logs a warning" do
            allow(@oauth).to receive(:parse_signed_request).and_return({})
            expect(Koala::Utils.logger).to receive(:warn)
            @oauth.get_user_info_from_cookies(@cookie)
          end
        end

        context "if the code is present" do
          it "adds the access_token into the hash" do
            expect(@oauth.get_user_info_from_cookies(@cookie)["access_token"]).to eq(@token)
          end

          it "returns nil if the call to FB returns no data" do
            allow(@oauth).to receive(:get_access_token_info).and_return(nil)
            expect(@oauth.get_user_info_from_cookies(@cookie)).to be_nil
          end

          it "returns nil if the call to FB returns an expired code error" do
            allow(@oauth).to receive(:get_access_token_info).and_raise(Koala::Facebook::OAuthTokenRequestError.new(400,
                                                                                                                   '{ "error": { "type": "OAuthException", "message": "Code was invalid or expired. Session has expired at unix time 1324044000. The current unix time is 1324300957." } }'
                                                                                                                  ))
            expect(@oauth.get_user_info_from_cookies(@cookie)).to be_nil
          end

          it "raises the error if the call to FB returns a different error" do
            allow(@oauth).to receive(:get_access_token_info).and_raise(Koala::Facebook::OAuthTokenRequestError.new(400,
                                                                                                                   '{ "error": { "type": "OtherError", "message": "A Facebook Error" } }'))
            expect { @oauth.get_user_info_from_cookies(@cookie) }.to raise_exception(Koala::Facebook::OAuthTokenRequestError)
          end
        end

        it "doesn't parse invalid cookies" do
          # make an invalid string by replacing some values
          bad_cookie_hash = @cookie.inject({}) { |hash, value| hash[value[0]] = value[1].gsub(/[0-9]/, "3") }
          result = @oauth.get_user_info_from_cookies(bad_cookie_hash)
          expect(result).to be_nil
        end
      end

      context "for unsigned cookies" do
        it "properly parses valid cookies" do
          result = @oauth.get_user_info_from_cookies(KoalaTest.oauth_test_data["valid_cookies"])
          expect(result).to be_a(Hash)
        end

        it "returns all the cookie components from valid cookie string" do
          cookie_data = KoalaTest.oauth_test_data["valid_cookies"]
          parsing_results = @oauth.get_user_info_from_cookies(cookie_data)
          number_of_components = cookie_data["fbs_#{@app_id.to_s}"].scan(/\=/).length
          expect(parsing_results.length).to eq(number_of_components)
        end

        it "properly parses valid offline access cookies (e.g. no expiration)" do
          result = @oauth.get_user_info_from_cookies(KoalaTest.oauth_test_data["offline_access_cookies"])
          expect(result["uid"]).to be_truthy
        end

        it "returns all the cookie components from offline access cookies" do
          cookie_data = KoalaTest.oauth_test_data["offline_access_cookies"]
          parsing_results = @oauth.get_user_info_from_cookies(cookie_data)
          number_of_components = cookie_data["fbs_#{@app_id.to_s}"].scan(/\=/).length
          expect(parsing_results.length).to eq(number_of_components)
        end

        it "doesn't parse expired cookies" do
          new_time = @time.to_i * 2
          allow(@time).to receive(:to_i).and_return(new_time)
          expect(@oauth.get_user_info_from_cookies(KoalaTest.oauth_test_data["valid_cookies"])).to be_nil
        end

        it "doesn't parse invalid cookies" do
          # make an invalid string by replacing some values
          bad_cookie_hash = KoalaTest.oauth_test_data["valid_cookies"].inject({}) { |hash, value| hash[value[0]] = value[1].gsub(/[0-9]/, "3") }
          result = @oauth.get_user_info_from_cookies(bad_cookie_hash)
          expect(result).to be_nil
        end
      end
    end

    describe "for URL generation" do
      describe "#url_for_oauth_code" do
        it "generates a properly formatted OAuth code URL with the default values" do
          url = @oauth.url_for_oauth_code
          expect(url).to match_url("https://#{Koala.config.dialog_host}/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{CGI.escape @callback_url}")
        end

        it "includes the api version if specified" do
          version = Koala.config.api_version = "v.2.2.2.2"
          url = @oauth.url_for_oauth_code
          expect(url).to match_url("https://#{Koala.config.dialog_host}/#{version}/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{CGI.escape @callback_url}")
        end

        it "generates a properly formatted OAuth code URL when a callback is given" do
          callback = "foo.com"
          url = @oauth.url_for_oauth_code(:callback => callback)
          expect(url).to match_url("https://#{Koala.config.dialog_host}/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{callback}")
        end

        it "generates a properly formatted OAuth code URL when permissions are requested as a string" do
          permissions = "publish_stream,read_stream"
          url = @oauth.url_for_oauth_code(:permissions => permissions)
          expect(url).to match_url("https://#{Koala.config.dialog_host}/dialog/oauth?client_id=#{@app_id}&scope=#{CGI.escape permissions}&redirect_uri=#{CGI.escape @callback_url}")
        end

        it "generates a properly formatted OAuth code URL when permissions are requested as a string" do
          permissions = ["publish_stream", "read_stream"]
          url = @oauth.url_for_oauth_code(:permissions => permissions)
          expect(url).to match_url("https://#{Koala.config.dialog_host}/dialog/oauth?client_id=#{@app_id}&scope=#{CGI.escape permissions.join(",")}&redirect_uri=#{CGI.escape @callback_url}")
        end

        it "generates a properly formatted OAuth code URL when both permissions and callback are provided" do
          permissions = "publish_stream,read_stream"
          callback = "foo.com"
          url = @oauth.url_for_oauth_code(:callback => callback, :permissions => permissions)
          expect(url).to match_url("https://#{Koala.config.dialog_host}/dialog/oauth?client_id=#{@app_id}&scope=#{CGI.escape permissions}&redirect_uri=#{CGI.escape callback}")
        end

        it "generates a properly formatted OAuth code URL when a display is given as a string" do
          url = @oauth.url_for_oauth_code(:display => "page")
          expect(url).to match_url("https://#{Koala.config.dialog_host}/dialog/oauth?client_id=#{@app_id}&display=page&redirect_uri=#{CGI.escape @callback_url}")
        end

        it "raises an exception if no callback is given in initialization or the call" do
          oauth2 = Koala::Facebook::OAuth.new(@app_id, @secret)
          expect { oauth2.url_for_oauth_code }.to raise_error(ArgumentError)
        end

        it "includes any additional options as URL parameters, appropriately escaped" do
          params = {
            :url => "http://foo.bar?c=2",
            :email => "cdc@b.com"
          }
          url = @oauth.url_for_oauth_code(params)
          params.each_pair do |key, value|
            expect(url).to match(/[\&\?]#{key}=#{CGI.escape value}/)
          end
        end
      end

      describe "#url_for_access_token" do
        before :each do
          # since we're just composing a URL here, we don't need to have a real code
          @code ||= "test_code"
        end

        it "generates a properly formatted OAuth token URL when provided a code" do
          url = @oauth.url_for_access_token(@code)
          expect(url).to match_url("https://#{Koala.config.graph_server}/oauth/access_token?client_id=#{@app_id}&code=#{@code}&client_secret=#{@secret}&redirect_uri=#{CGI.escape @callback_url}")
        end

        it "includes the api version if specified" do
          version = Koala.config.api_version = "v.2.2.2.2"
          url = @oauth.url_for_access_token(@code)
          expect(url).to match_url("https://#{Koala.config.graph_server}/#{version}/oauth/access_token?client_id=#{@app_id}&code=#{@code}&client_secret=#{@secret}&redirect_uri=#{CGI.escape @callback_url}")
        end

        it "generates a properly formatted OAuth token URL when provided a callback" do
          callback = "foo.com"
          url = @oauth.url_for_access_token(@code, :callback => callback)
          expect(url).to match_url("https://#{Koala.config.graph_server}/oauth/access_token?client_id=#{@app_id}&code=#{@code}&client_secret=#{@secret}&redirect_uri=#{CGI.escape callback}")
        end

        it "includes any additional options as URL parameters, appropriately escaped" do
          params = {
            :url => "http://foo.bar?c=2",
            :email => "cdc@b.com"
          }
          url = @oauth.url_for_access_token(@code, params)
          params.each_pair do |key, value|
            expect(url).to match(/[\&\?]#{key}=#{CGI.escape value}/)
          end
        end
      end

      describe "#url_for_dialog" do
        it "builds the base properly" do
          dialog_type = "my_dialog_type"
          expect(@oauth.url_for_dialog(dialog_type)).to match(/^https:\/\/#{Koala.config.dialog_host}\/dialog\/#{dialog_type}/)
        end

        it "includes the api version if specified" do
          version = Koala.config.api_version = "v.2.2.2.2"
          dialog_type = "my_dialog_type"
          expect(@oauth.url_for_dialog(dialog_type)).to match("https:\/\/#{Koala.config.dialog_host}\/#{version}\/dialog\/#{dialog_type}")
        end

        it "adds the app_id/client_id to the url" do
          automatic_params = {:app_id => @app_id, :client_id => @client_id}
          url = @oauth.url_for_dialog("foo", automatic_params)
          automatic_params.each_pair do |key, value|
            # we're slightly simplifying how encode_params works, but for strings/ints, it's okay
            expect(url).to match(/[\&\?]#{key}=#{CGI.escape value.to_s}/)
          end
        end

        it "includes any additional options as URL parameters, appropriately escaped" do
          params = {
            :url => "http://foo.bar?c=2",
            :email => "cdc@b.com"
          }
          url = @oauth.url_for_dialog("friends", params)
          params.each_pair do |key, value|
            # we're slightly simplifying how encode_params works, but strings/ints, it's okay
            expect(url).to match(/[\&\?]#{key}=#{CGI.escape value.to_s}/)
          end
        end

        describe "real examples from FB documentation" do
          # see http://developers.facebook.com/docs/reference/dialogs/
          # slightly brittle (e.g. if parameter order changes), but still useful
          it "can generate a send dialog" do
            url = @oauth.url_for_dialog("send", :name => "People Argue Just to Win", :link => "http://www.nytimes.com/2011/06/15/arts/people-argue-just-to-win-scholars-assert.html")
            expect(url).to match_url("https://www.facebook.com/dialog/send?app_id=#{@app_id}&client_id=#{@app_id}&link=http%3A%2F%2Fwww.nytimes.com%2F2011%2F06%2F15%2Farts%2Fpeople-argue-just-to-win-scholars-assert.html&name=People+Argue+Just+to+Win&redirect_uri=#{CGI.escape @callback_url}")
          end

          it "can generate a feed dialog" do
            url = @oauth.url_for_dialog("feed", :name => "People Argue Just to Win", :link => "http://www.nytimes.com/2011/06/15/arts/people-argue-just-to-win-scholars-assert.html")
            expect(url).to match_url("https://www.facebook.com/dialog/feed?app_id=#{@app_id}&client_id=#{@app_id}&link=http%3A%2F%2Fwww.nytimes.com%2F2011%2F06%2F15%2Farts%2Fpeople-argue-just-to-win-scholars-assert.html&name=People+Argue+Just+to+Win&redirect_uri=#{CGI.escape @callback_url}")
          end

          it "can generate a oauth dialog" do
            url = @oauth.url_for_dialog("oauth", :scope => "email", :response_type => "token")
            expect(url).to match_url("https://www.facebook.com/dialog/oauth?app_id=#{@app_id}&client_id=#{@app_id}&redirect_uri=#{CGI.escape @callback_url}&response_type=token&scope=email")
          end

          it "can generate a pay dialog" do
            url = @oauth.url_for_dialog("pay", :order_id => "foo", :credits_purchase => false)
            expect(url).to match_url("https://www.facebook.com/dialog/pay?app_id=#{@app_id}&client_id=#{@app_id}&order_id=foo&credits_purchase=false&redirect_uri=#{CGI.escape @callback_url}")
          end
        end
      end
    end

    describe 'for generating a client code' do
      describe '#generate_client_code' do
        if KoalaTest.mock_interface? || KoalaTest.oauth_token
          it 'makes a request using the correct endpoint' do
            expect(Koala).to receive(:make_request).with('/oauth/client_code', anything, 'get', anything).and_return(Koala::HTTPService::Response.new(200, '{"code": "fake_client_code"}', {}))
            @oauth.generate_client_code(KoalaTest.oauth_token)
          end

          it 'gets a valid client code returned' do
            expect(Koala).to receive(:make_request).with('/oauth/client_code', anything, 'get', anything).and_return(Koala::HTTPService::Response.new(200, '{"code": "fake_client_code"}', {}))
            result = @oauth.generate_client_code(KoalaTest.oauth_token)
            expect(result).to be_a(String)
            expect(result).to eq('fake_client_code')
          end

          it 'raises a BadFacebookResponse error when empty response body is returned' do
            expect(Koala).to receive(:make_request).with('/oauth/client_code', anything, 'get', anything).and_return(Koala::HTTPService::Response.new(200, '', {}))
            expect { @oauth.generate_client_code(KoalaTest.oauth_token) }.to raise_error(Koala::Facebook::BadFacebookResponse)
          end

          it 'raises an OAuthTokenRequestError when empty response body is returned' do
            expect(Koala).to receive(:make_request).with('/oauth/client_code', anything, 'get', anything).and_return(Koala::HTTPService::Response.new(400, '', {}))
            expect { @oauth.generate_client_code(KoalaTest.oauth_token) }.to raise_error(Koala::Facebook::OAuthTokenRequestError)
          end

          it 'raises a ServerError when empty response body is returned' do
            expect(Koala).to receive(:make_request).with('/oauth/client_code', anything, 'get', anything).and_return(Koala::HTTPService::Response.new(500, '', {}))
            expect { @oauth.generate_client_code(KoalaTest.oauth_token) }.to raise_error(Koala::Facebook::ServerError)
          end

          it 'raises a KoalaError when empty response body is returned' do
            expect(Koala).to receive(:make_request).with('/oauth/client_code', anything, 'get', anything).and_return(Koala::HTTPService::Response.new(200, '{"client_code":"should_not_be_returned"}', {}))
            expect { @oauth.generate_client_code(KoalaTest.oauth_token) }.to raise_error(Koala::KoalaError)
          end
        else
          pending "Some OAuth token exchange tests will not be run since the access token field in facebook_data.yml is blank."
        end
      end
    end

    describe "for fetching access tokens" do
      describe "#get_access_token_info" do
        it "uses options[:redirect_uri] if provided" do
          uri = "foo"
          expect(Koala).to receive(:make_request).with(anything, hash_including(:redirect_uri => uri), anything, anything).and_return(Koala::HTTPService::Response.new(200, "", {}))
          @oauth.get_access_token_info(@code, :redirect_uri => uri)
        end

        it "uses the redirect_uri used to create the @oauth if no :redirect_uri option is provided" do
          expect(Koala).to receive(:make_request).with(anything, hash_including(:redirect_uri => @callback_url), anything, anything).and_return(Koala::HTTPService::Response.new(200, "", {}))
          @oauth.get_access_token_info(@code)
        end

        it "makes a GET request" do
          expect(Koala).to receive(:make_request).with(anything, anything, "get", anything).and_return(Koala::HTTPService::Response.new(200, "", {}))
          @oauth.get_access_token_info(@code)
        end

        it "properly decodes JSON results" do
          result =  {
            "access_token" => "foo",
            "expires_in" => "baz",
            "machine_id" => "bar"
          }
          allow(Koala).to receive(:make_request).and_return(
            Koala::HTTPService::Response.new(
              200,
              JSON.dump(result),
              {}
            )
          )
          expect(@oauth.get_access_token_info(@code)).to eq(result)
        end

        it "falls back to URL-style parsing " do
          result = "access_token=foo&expires_in=baz&machine_id=bar"
          allow(Koala).to receive(:make_request).and_return(
            Koala::HTTPService::Response.new(200, result, {})
          )
          expect(@oauth.get_access_token_info(@code)).to eq({
            "access_token" => "foo",
            "expires_in" => "baz",
            "machine_id" => "bar"
          })
        end

        if KoalaTest.code
          it "properly gets and parses an access token token results into a hash" do
            result = @oauth.get_access_token_info(@code)
            expect(result).to be_a(Hash)
          end

          it "properly includes the access token results" do
            result = @oauth.get_access_token_info(@code)
            expect(result["access_token"]).to be_truthy
          end

          it "raises an error when get_access_token is called with a bad code" do
            expect { @oauth.get_access_token_info("foo") }.to raise_error(Koala::Facebook::OAuthTokenRequestError)
          end
        end
      end

      describe "#get_access_token" do
        # TODO refactor these to be proper tests with stubs and tests against real data
        it "passes on any options provided to make_request" do
          options = {:a => 2}
          expect(Koala).to receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
          @oauth.get_access_token(@code, options)
        end

        if KoalaTest.code
          it "uses get_access_token_info to get and parse an access token token results" do
            result = @oauth.get_access_token(@code)
            expect(result).to be_a(String)
          end

          it "returns the access token as a string" do
            result = @oauth.get_access_token(@code)
            original = @oauth.get_access_token_info(@code)
            expect(result).to eq(original["access_token"])
          end

          it "raises an error when get_access_token is called with a bad code" do
            expect { @oauth.get_access_token("foo") }.to raise_error(Koala::Facebook::OAuthTokenRequestError)
          end
        end
      end

      unless KoalaTest.code
        it "Some OAuth code tests will not be run since the code field in facebook_data.yml is blank."
      end

      describe "get_app_access_token_info" do
        it "properly gets and parses an app's access token as a hash" do
          result = @oauth.get_app_access_token_info
          expect(result).to be_a(Hash)
        end

        it "includes the access token" do
          result = @oauth.get_app_access_token_info
          expect(result["access_token"]).to be_truthy
        end

        it "passes on any options provided to make_request" do
          options = {:a => 2}
          expect(Koala).to receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
          @oauth.get_app_access_token_info(options)
        end
      end

      describe "get_app_access_token" do
        it "uses get_access_token_info to get and parse an access token token results" do
          result = @oauth.get_app_access_token
          expect(result).to be_a(String)
        end

        it "returns the access token as a string" do
          result = @oauth.get_app_access_token
          original = @oauth.get_app_access_token_info
          expect(result).to eq(original["access_token"])
        end

        it "passes on any options provided to make_request" do
          options = {:a => 2}
          expect(Koala).to receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
          @oauth.get_app_access_token(options)
        end
      end

      describe "exchange_access_token_info" do
        if KoalaTest.mock_interface? || KoalaTest.oauth_token
          it "properly gets and parses an app's access token as a hash" do
            result = @oauth.exchange_access_token_info(KoalaTest.oauth_token)
            expect(result).to be_a(Hash)
          end

          it "includes the access token" do
            result = @oauth.exchange_access_token_info(KoalaTest.oauth_token)
            expect(result["access_token"]).not_to be_nil
          end
        else
          pending "Some OAuth token exchange tests will not be run since the access token field in facebook_data.yml is blank."
        end

        it "passes on any options provided to make_request" do
          options = {:a => 2}
          expect(Koala).to receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
          @oauth.exchange_access_token_info(KoalaTest.oauth_token, options)
        end

        it "raises an error when exchange_access_token_info is called with a bad code" do
          expect { @oauth.exchange_access_token_info("foo") }.to raise_error(Koala::Facebook::OAuthTokenRequestError)
        end
      end

      describe "exchange_access_token" do
        it "uses get_access_token_info to get and parse an access token token results" do
          hash = {"access_token" => Time.now.to_i * rand}
          allow(@oauth).to receive(:exchange_access_token_info).and_return(hash)
          expect(@oauth.exchange_access_token(KoalaTest.oauth_token)).to eq(hash["access_token"])
        end

        it "passes on any options provided to make_request" do
          options = {:a => 2}
          expect(Koala).to receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
          @oauth.exchange_access_token(KoalaTest.oauth_token, options)
        end
      end

      describe "protected methods" do
        # protected methods
        # since these are pretty fundamental and pretty testable, we want to test them

        # parse_access_token
        it "properly parses access token results" do
          result = @oauth.send(:parse_access_token, @raw_token_string)
          has_both_parts = result["access_token"] && result["expires"]
          expect(has_both_parts).to be_truthy
        end

        it "properly parses offline access token results" do
          result = @oauth.send(:parse_access_token, @raw_offline_access_token_string)
          has_both_parts = result["access_token"] && !result["expires"]
          expect(has_both_parts).to be true
        end

        # fetch_token_string
        # somewhat duplicative with the tests for get_access_token and get_app_access_token
        # but no harm in thoroughness
        if KoalaTest.code
          it "fetches a proper token string from Facebook when given a code" do
            result = @oauth.send(:fetch_token_string, :code => @code, :redirect_uri => @callback_url)
            expect(result).to match(/^access_token/)
          end
        else
          it "fetch_token_string code test will not be run since the code field in facebook_data.yml is blank."
        end

        it "fetches a proper token string from Facebook when asked for the app token" do
          result = @oauth.send(:fetch_token_string, {:grant_type => 'client_credentials'}, true)
          expect(result).to match(/^access_token/)
        end
      end
    end

    describe "for parsing signed requests" do
      # the signed request code is ported directly from Facebook
      # so we only need to test at a high level that it works
      it "throws an error if the algorithm is unsupported" do
        allow(JSON).to receive(:parse).and_return("algorithm" => "my fun algorithm")
        expect { @oauth.parse_signed_request(@signed_params) }.to raise_error(Koala::Facebook::OAuthSignatureError)
      end

      it "throws an error if the signature is invalid" do
        allow(OpenSSL::HMAC).to receive(:hexdigest).and_return("i'm an invalid signature")
        expect { @oauth.parse_signed_request(@signed_params) }.to raise_error(Koala::Facebook::OAuthSignatureError)
      end

      it "throws an error if the signature string is empty" do
        # this occasionally happens due to Facebook error
        expect { @oauth.parse_signed_request("") }.to raise_error(Koala::Facebook::OAuthSignatureError)
        expect { @oauth.parse_signed_request("abc-def") }.to raise_error(Koala::Facebook::OAuthSignatureError)
      end

      it "properly parses requests" do
        @oauth = Koala::Facebook::OAuth.new(@app_id, @secret || @app_secret)
        expect(@oauth.parse_signed_request(@signed_params)).to eq(@signed_params_result)
      end
    end
  end
end # describe

require 'spec_helper'

describe "Koala::Facebook::TestUsers" do
  before :all do
    # get oauth data
    @app_id = KoalaTest.app_id
    @secret = KoalaTest.secret
    @app_access_token = KoalaTest.app_access_token

    @test_users = Koala::Facebook::TestUsers.new({:app_access_token => @app_access_token, :app_id => @app_id})

    # check OAuth data
    unless @app_id && @secret && @app_access_token
      raise Exception, "Must supply OAuth app id, secret, app_access_token, and callback to run live subscription tests!"
    end
  end

  after :each do
    # clean up any test users
    # Facebook only allows us 500 test users per app, so we have to clean up
    # This would be a good place to clean up and accumulate all of them for
    # later deletion.
    unless KoalaTest.mock_interface? || @stubbed
      ((@network || []) + [@user1, @user2]).each do |u|
        puts "Unable to delete test user #{u.inspect}" if u && !(@test_users.delete(u) rescue false)
      end
    end
  end

  describe "when initializing" do
    # basic initialization
    it "initializes properly with an app_id and an app_access_token" do
      test_users = Koala::Facebook::TestUsers.new(:app_id => @app_id, :app_access_token => @app_access_token)
      expect(test_users).to be_a(Koala::Facebook::TestUsers)
    end

    # init with secret / fetching the token
    it "initializes properly with an app_id and a secret" do
      test_users = Koala::Facebook::TestUsers.new(:app_id => @app_id, :secret => @secret)
      expect(test_users).to be_a(Koala::Facebook::TestUsers)
    end

    context "with global defaults" do
      let(:app_id) { :app_id }
      let(:app_secret) { :app_secret }
      let(:app_access_token) { :app_access_token }

      before :each do
        Koala.configure do |config|
          config.app_id = app_id
          config.app_secret = app_secret
          config.app_access_token = app_access_token
        end
      end

      it "defaults to the configured data if not otherwise provided" do
        test_users = Koala::Facebook::TestUsers.new
        expect(test_users.app_id).to eq(app_id)
        expect(test_users.secret).to eq(app_secret)
        expect(test_users.app_access_token).to eq(app_access_token)
      end

      it "lets you override app_id" do
        other_value = :another_id
        test_users = Koala::Facebook::TestUsers.new(app_id: other_value)
        expect(test_users.app_id).to eq(other_value)
      end

      it "lets you override secret" do
        other_value = :another_secret
        test_users = Koala::Facebook::TestUsers.new(secret: other_value)
        expect(test_users.secret).to eq(other_value)
      end

      it "lets you override app_id" do
        other_value = :another_token
        test_users = Koala::Facebook::TestUsers.new(app_access_token: other_value)
        expect(test_users.app_access_token).to eq(other_value)
      end
    end


    it "uses the OAuth class to fetch a token when provided an app_id and a secret" do
      oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
      token = oauth.get_app_access_token
      expect(oauth).to receive(:get_app_access_token).and_return(token)
      expect(Koala::Facebook::OAuth).to receive(:new).with(@app_id, @secret).and_return(oauth)
      Koala::Facebook::TestUsers.new(:app_id => @app_id, :secret => @secret)
    end

    # attributes
    it "allows read access to app_id, app_access_token, and secret" do
      # in Ruby 1.9, .method returns symbols
      expect(Koala::Facebook::TestUsers.instance_methods.map(&:to_sym)).to include(:app_id)
      expect(Koala::Facebook::TestUsers.instance_methods.map(&:to_sym)).not_to include(:app_id=)
    end

    it "allows read access to app_access_token" do
      # in Ruby 1.9, .method returns symbols
      expect(Koala::Facebook::TestUsers.instance_methods.map(&:to_sym)).to include(:app_access_token)
      expect(Koala::Facebook::TestUsers.instance_methods.map(&:to_sym)).not_to include(:app_access_token=)
    end

    it "allows read access to secret" do
      # in Ruby 1.9, .method returns symbols
      expect(Koala::Facebook::TestUsers.instance_methods.map(&:to_sym)).to include(:secret)
      expect(Koala::Facebook::TestUsers.instance_methods.map(&:to_sym)).not_to include(:secret=)
    end

    it "allows read access to api" do
      # in Ruby 1.9, .method returns symbols
      expect(Koala::Facebook::TestUsers.instance_methods.map(&:to_sym)).to include(:api)
      expect(Koala::Facebook::TestUsers.instance_methods.map(&:to_sym)).not_to include(:api=)
    end
  end

  describe "when used without network" do
    # TEST USER MANAGEMENT

    describe "#create" do
      it "creates a test user when not given installed" do
        result = @test_users.create(false)
        @user1 = result["id"]
        expect(result).to be_a(Hash)
        expect(result["id"] && result["access_token"] && result["login_url"]).to be_truthy
      end

      it "creates a test user when not given installed, ignoring permissions" do
        result = @test_users.create(false, "read_stream")
        @user1 = result["id"]
        expect(result).to be_a(Hash)
        expect(result["id"] && result["access_token"] && result["login_url"]).to be_truthy
      end

      it "accepts permissions as a string" do
        expect(@test_users.api).to receive(:graph_call).with(anything, hash_including("permissions" => "read_stream,publish_stream"), anything, anything)
        result = @test_users.create(true, "read_stream,publish_stream")
      end

      it "accepts permissions as an array" do
        expect(@test_users.api).to receive(:graph_call).with(anything, hash_including("permissions" => "read_stream,publish_stream"), anything, anything)
        result = @test_users.create(true, ["read_stream", "publish_stream"])
      end

      it "creates a test user when given installed and a permission" do
        result = @test_users.create(true, "read_stream")
        @user1 = result["id"]
        expect(result).to be_a(Hash)
        expect(result["id"] && result["access_token"] && result["login_url"]).to be_truthy
      end

      it "lets you specify other graph arguments, like uid and access token" do
        args = {:uid => "some test user ID", :owner_access_token => "some owner access token"}
        expect(@test_users.api).to receive(:graph_call).with(anything, hash_including(args), anything, anything)
        @test_users.create(true, nil, args)
      end

      it "lets you specify http options that get passed through to the graph call" do
        options = {:some_http_option => true}
        expect(@test_users.api).to receive(:graph_call).with(anything, anything, anything, options)
        @test_users.create(true, nil, {}, options)
      end
    end

    describe "#list" do
      before :each do
        @user1 = @test_users.create(true, "read_stream")
        @user2 = @test_users.create(true, "read_stream,user_interests")
      end

      it "lists test users" do
        result = @test_users.list
        expect(result).to be_an(Array)
        first_user, second_user = result[0], result[1]
        expect(first_user["id"] && first_user["access_token"] && first_user["login_url"]).to be_truthy
        expect(second_user["id"] && second_user["access_token"] && second_user["login_url"]).to be_truthy
      end

      it "accepts http options" do
        @stubbed = true
        options = {:some_http_option => true}
        expect(@test_users.api).to receive(:graph_call).with(anything, anything, anything, options)
        @test_users.list(options)
      end
    end

    describe "#delete" do
      before :each do
        @user1 = @test_users.create(true, "read_stream")
        @user2 = @test_users.create(true, "read_stream,user_interests")
      end

      it "deletes a user by id" do
        expect(@test_users.delete(@user1['id'])).to be_truthy
        @user1 = nil
      end

      it "deletes a user by hash" do
        expect(@test_users.delete(@user2)).to be_truthy
        @user2 = nil
      end

      it "does not delete users when provided a false ID" do
        expect { @test_users.delete("#{@user1['id']}1") }.to raise_exception(Koala::Facebook::APIError)
      end

      it "lets you specify http options that get passed through to the graph call" do
        options = {:some_http_option => true}
        # technically this goes through delete_object, but this makes it less brittle
        @stubbed = true
        expect(@test_users.api).to receive(:graph_call).with(anything, anything, anything, options)
        @test_users.delete("user", options)
      end
    end

    describe "#delete_all" do
      it "deletes the batch API to deleten all users found by the list commnand" do
        array = 200.times.collect { {"id" => rand}}
        expect(@test_users).to receive(:list).and_return(array, [])
        batch_api = double("batch API")
        allow(@test_users.api).to receive(:batch).and_yield(batch_api)
        array.each {|item| expect(batch_api).to receive(:delete_object).with(item["id"]) }
        @test_users.delete_all
      end

      it "accepts http options that get passed to both list and the batch call" do
        options = {:some_http_option => true}
        expect(@test_users).to receive(:list).with(options).and_return([{"id" => rand}], [])
        expect(@test_users.api).to receive(:batch).with(options)
        @test_users.delete_all(options)
      end

      it "breaks if Facebook sends back the same list twice" do
        list = [{"id" => rand}]
        allow(@test_users).to receive(:list).and_return(list)
        expect(@test_users.api).to receive(:batch).once
        @test_users.delete_all
      end

      it "breaks if the same list comes back, even if the hashes differ" do
        list1 = [{"id" => 123}]
        list2 = [{"id" => 123, "name" => "foo"}]
        allow(@test_users).to receive(:list).twice.and_return(list1, list2)
        expect(@test_users.api).to receive(:batch).once
        @test_users.delete_all
      end
    end

    describe "#update" do
      before :each do
        @updates = {:name => "Foo Baz"}
        # we stub out :graph_call, but still need to be able to delete the users
        @test_users2 = Koala::Facebook::TestUsers.new(:app_id => @test_users.app_id, :app_access_token => @test_users.app_access_token)
      end

      it "makes a POST with the test user Graph API " do
        @user1 = @test_users2.create(true)
        expect(@test_users2.api).to receive(:graph_call).with(anything, anything, "post", anything)
        @test_users2.update(@user1, @updates)
      end

      it "makes a request to the test user with the update params " do
        @user1 = @test_users2.create(true)
        expect(@test_users2.api).to receive(:graph_call).with(@user1["id"], @updates, anything, anything)
        @test_users2.update(@user1, @updates)
      end

      it "accepts an options hash" do
        options = {:some_http_option => true}
        @stubbed = true
        expect(@test_users2.api).to receive(:graph_call).with(anything, anything, anything, options)
        @test_users2.update("foo", @updates, options)
      end

      it "works" do
        @user1 = @test_users.create(true)
        @test_users.update(@user1, @updates)
        user_info = Koala::Facebook::API.new(@user1["access_token"]).get_object(@user1["id"])
        expect(user_info["name"]).to eq(@updates[:name])
      end
    end

    describe "#befriend" do
      before :each do
        @user1 = @test_users.create(true, "read_stream")
        @user2 = @test_users.create(true, "read_stream,user_interests")
      end

      it "makes two users into friends with string hashes" do
        result = @test_users.befriend(@user1, @user2)
        expect(result).to be_truthy
      end

      it "makes two users into friends with symbol hashes" do
        new_user_1 = {}
        @user1.each_pair {|k, v| new_user_1[k.to_sym] = v}
        new_user_2 = {}
        @user2.each_pair {|k, v| new_user_2[k.to_sym] = v}

        result = @test_users.befriend(new_user_1, new_user_2)
        expect(result).to be_truthy
      end

      it "accepts http options passed to both calls" do
        options = {:some_http_option => true}
        # should come twice, once for each user
        @stubbed = true
        expect(Koala.http_service).to receive(:make_request).twice do |request|
          expect(request.raw_options).to eq(options)
          Koala::HTTPService::Response.new(200, "{}", {})
        end
        @test_users.befriend(@user1, @user2, options)
      end

      it "includes the secret, generating the appsecret_proof in both calls if provided" do
        # should come twice, once for each user
        @stubbed = true
        test_users = Koala::Facebook::TestUsers.new({:secret => @secret, :app_id => @app_id})
        expect(Koala.http_service).to receive(:make_request).twice do |request|
          expect(request.post_args).to include("appsecret_proof")
          Koala::HTTPService::Response.new(200, "{}", {})
        end
        test_users.befriend(@user1, @user2)
      end
    end
  end # when used without network

  describe "#test_user_accounts_path" do
    it "returns the app_id/accounts/test-users" do
      expect(@test_users.test_user_accounts_path).to eq("/#{@app_id}/accounts/test-users")
    end
  end

  describe "when creating a network of friends" do
    before :each do
      @network = []

      if KoalaTest.mock_interface?
        id_counter = 999999900
        allow(@test_users).to receive(:create) do
          id_counter += 1
          {"id" => id_counter, "access_token" => @token, "login_url" => "https://www.facebook.com/platform/test_account.."}
        end
        allow(@test_users).to receive(:befriend).and_return(true)
        allow(@test_users).to receive(:delete).and_return(true)
      end
    end

    describe "tests that create users" do
      it "creates a 5 person network" do
        size = 5
        @network = @test_users.create_network(size)
        expect(@network).to be_a(Array)
        expect(@network.size).to eq(size)
      end
    end

    it "has no built-in network size limit" do
      times = 100
      expect(@test_users).to receive(:create).exactly(times).times
      allow(@test_users).to receive(:befriend)
      @test_users.create_network(times)
    end

    it "passes on the installed and permissions parameters to create" do
      perms = ["read_stream", "offline_access"]
      installed = false
      count = 25
      expect(@test_users).to receive(:create).exactly(count).times.with(installed, perms, anything, anything)
      allow(@test_users).to receive(:befriend)
      @test_users.create_network(count, installed, perms)
    end

    it "accepts http options that are passed to both the create and befriend calls" do
      count = 25
      options = {:some_http_option => true}
      expect(@test_users).to receive(:create).exactly(count).times.with(anything, anything, anything, options).and_return({})
      # there are more befriends than creates, but we don't need to do the extra work to calculate out the exact #
      expect(@test_users).to receive(:befriend).at_least(count).times.with(anything, anything, options)
      @test_users.create_network(count, true, "", options)
    end
  end # when creating network
end  # describe Koala TestUsers

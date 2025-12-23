shared_examples_for "Koala GraphAPI" do
  # all Graph API instances should pass these tests, regardless of configuration
  let(:dummy_response) { double("fake response", data: {}, status: 200, body: "", headers: {}) }

  # API
  it "never uses the rest api server" do
    expect(Koala).to receive(:make_request).with(
      anything,
      anything,
      anything,
      hash_not_including(:rest_api => true)
    ).and_return(Koala::HTTPService::Response.new(200, "", {}))

    @api.api("anything")
  end

  # DATA

  describe "#get_picture" do
    it "can access a user's picture" do
      expect(@api.get_picture(KoalaTest.user2)).to match(/https?\:\/\//)
    end

    it "can access a user's picture, given a picture type"  do
      expect(@api.get_picture(KoalaTest.user2, {:type => 'large'})).to match(/^https?\:\/\//)
    end

    it "works even if Facebook returns nil" do
      allow(@api).to receive(:graph_call).and_return(nil)
      expect(@api.get_picture(KoalaTest.user2, {:type => 'large'})).to be_nil
    end
  end

  describe "#get_picture_data" do
    it "can access a user's picture data" do
      result = @api.get_picture_data(KoalaTest.user2)
      expect(result).to be_kind_of(Hash)
      expect(result["data"]).to be_kind_of(Hash)
      expect(result['data']).to be_truthy
      expect(result['data'].keys).to include('is_silhouette', 'url')
    end
  end

  describe "#get_user_picture_data" do
    it "can access a user's picture data" do
      result = @api.get_picture_data(KoalaTest.user2)
      expect(result).to be_kind_of(Hash)
      expect(result["data"]).to be_kind_of(Hash)
      expect(result['data']).to be_truthy
      expect(result['data'].keys).to include('is_silhouette', 'url')
    end
  end

  # PAGING THROUGH COLLECTIONS
  # see also graph_collection_tests
  it "makes a request for a page when provided a specific set of page params" do
    query = [1, 2]
    expect(@api).to receive(:graph_call).with(*query)
    @api.get_page(query)
  end
end


shared_examples_for "Koala GraphAPI with an access token" do
  let(:dummy_response) { double("fake response", data: {}, status: 200, body: "", headers: {}) }

  it "gets public data about a user" do
    result = @api.get_object(KoalaTest.user1)
    # the results should have an ID and a name, among other things
    expect(result["id"] && result["name"]).not_to be_nil
  end

  it "gets public data about a Page" do
    begin
      Koala::Utils.level = 0
      result = @api.get_object(KoalaTest.page)
      # the results should have an ID and a name, among other things
      expect(result["id"] && result["name"]).to be_truthy
    ensure
      Koala::Utils.level = Logger::ERROR
    end
  end

  it "returns [] from get_objects if passed an empty array" do
    results = @api.get_objects([])
    expect(results).to eq([])
  end

  it "gets multiple objects" do
    results = @api.get_objects([KoalaTest.page, KoalaTest.user1])
    expect(results.size).to eq(2)
  end

  it "gets multiple objects if they're a string" do
    results = @api.get_objects("facebook,#{KoalaTest.user1}")
    expect(results.size).to eq(2)
  end

  it "gets private data about a user" do
    result = @api.get_object(KoalaTest.user1)
    # updated_time should be a pretty fixed test case
    expect(result["updated_time"]).not_to be_nil
  end

  it "gets data about 'me'" do
    result = @api.get_object("me")
    expect(result["updated_time"]).to be_truthy
  end

  it "gets multiple objects" do
    begin
      Koala::Utils.level = 0
      result = @api.get_objects([KoalaTest.page, KoalaTest.user1])
      expect(result.length).to eq(2)
    ensure
      Koala::Utils.level = Logger::ERROR
    end
  end

  it "can access connections from public Pages" do
    result = @api.get_connections(KoalaTest.page, "events")
    expect(result).to be_a(Array)
  end

  describe "#get_object_metadata" do
    it "can access an object's metadata" do
      result = @api.get_object_metadata(KoalaTest.user1)
      expect(result["type"]).to eq("user")
    end
  end

  it "can access connections from users" do
    result = @api.get_connections(KoalaTest.user2, "likes")
    expect(result.length).to be > 0
  end

  # SEARCH
  it "can search" do
    result = @api.search("facebook", type: "page")
    expect(result.length).to be_an(Integer)
  end

  # PUT
  it "can write an object to the graph" do
    result = @api.put_wall_post("Hello, world, from the test suite!")
    @temporary_object_id = result["id"]
    expect(@temporary_object_id).not_to be_nil
  end

  # DELETE
  it "can delete posts" do
    result = @api.put_wall_post("Hello, world, from the test suite delete method!")
    object_id_to_delete = result["id"]
    delete_result = @api.delete_object(object_id_to_delete)
    expect(delete_result).to eq("success" => true)
  end

  it "can delete likes" do
    result = @api.put_wall_post("Hello, world, from the test suite delete like method!")
    @temporary_object_id = result["id"]
    @api.put_like(@temporary_object_id)
    delete_like_result = @api.delete_like(@temporary_object_id)
    expect(delete_like_result).to eq("success" => true)
  end

  # additional put tests
  it "can verify messages posted to a wall" do
    message = "the cats are asleep"
    put_result = @api.put_wall_post(message)
    @temporary_object_id = put_result["id"]
    get_result = @api.get_object(@temporary_object_id)

    # make sure the message we sent is the message that got posted
    expect(get_result["message"]).to eq(message)
  end

  it "can post a message with an attachment to a feed" do
    result = @api.put_wall_post("Hello, world, from the test suite again!", {:name => "OAuth Playground", :link => "http://testdomain.koalatest.test/"})
    @temporary_object_id = result["id"]
    expect(@temporary_object_id).not_to be_nil
  end

  it "can post a message whose attachment has a properties dictionary" do
    url = KoalaTest.oauth_test_data["callback_url"]
    args = {
      "picture" => "#{KoalaTest.oauth_test_data["callback_url"]}/images/logo.png",
      "name" => "It's a big question",
      "type" => "link",
      "link" => KoalaTest.oauth_test_data["callback_url"],
      "properties" => {
        "Link1" => {"text" => "Left", "href" => url},
        "other" => {"text" => "Straight ahead", "href" => url + "?"}
      }
    }

    result = @api.put_wall_post("body", args)
    @temporary_object_id = result["id"]
    expect(@temporary_object_id).not_to be_nil

    # ensure the properties dictionary is there
    api_data = @api.get_object(@temporary_object_id)
    expect(api_data["properties"]).not_to be_nil
  end

  describe "#put_picture" do
    context "with a file object" do
      let(:content_type) { "image/jpg" }
      let(:file) { File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg")) }
      let(:file_path) { File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg") }

      it "can post photos to the user's wall with an open file object" do
        result = @api.put_picture(file, content_type)
        @temporary_object_id = result["id"]
        expect(@temporary_object_id).not_to be_nil
      end

      it "can post photos to the user's wall without an open file object" do
        result = @api.put_picture(file_path, content_type)
        @temporary_object_id = result["id"]
        expect(@temporary_object_id).not_to be_nil
      end

      it "can verify a photo posted to a user's wall" do
        expected_message = "This is the test message"

        result = @api.put_picture(file_path, content_type, :message => expected_message)
        @temporary_object_id = result["id"]
        expect(@temporary_object_id).not_to be_nil

        get_result = @api.get_object(@temporary_object_id)
        expect(get_result["name"]).to eq(expected_message)
      end

      it "passes options and block through" do
        opts = {a: 2}
        block = Proc.new {}
        expect(@api).to receive(:graph_call).with(anything, anything, anything, hash_including(opts), &block)
        @api.put_picture(file_path, content_type, {:message => "my message"}, "target", opts, &block)
      end
    end

    describe "using a URL instead of a file" do
      let(:url) { "http://img.slate.com/images/redesign2008/slate_logo.gif" }

      it "can post photo to the user's wall using a URL" do
        result = @api.put_picture(url)
        @temporary_object_id = result["id"]
        expect(@temporary_object_id).not_to be_nil
      end

      it "can post photo to the user's wall using aurl and an additional param" do
        result = @api.put_picture(url, :message => "my message")
        @temporary_object_id = result["id"]
        expect(@temporary_object_id).not_to be_nil
      end
    end
  end

  describe "#put_video" do
    let(:cat_movie) { File.join(File.dirname(__FILE__), "..", "fixtures", "cat.m4v") }
    let(:content_type) { "video/mpeg4" }

    it "sets options[:video] to true" do
      source = double("UploadIO")
      allow(Koala::HTTPService::UploadableIO).to receive(:new).and_return(source)
      allow(source).to receive(:requires_base_http_service).and_return(false)
      expect(Koala).to receive(:make_request).with(anything, anything, anything, hash_including(:video => true)).and_return(Koala::HTTPService::Response.new(200, "[]", {}))
      @api.put_video("foo")
    end

    it "passes options and block through" do
      opts = {a: 2}
      block = Proc.new {}
      expect(@api).to receive(:graph_call).with(anything, anything, anything, hash_including(opts), &block)
      file = File.open(cat_movie)
      @api.put_video(file, content_type, {}, "target", opts, &block)
    end

    it "can post videos to the user's wall with an open file object" do
      file = File.open(cat_movie)

      result = @api.put_video(file, content_type)
      @temporary_object_id = result["id"]
      expect(@temporary_object_id).not_to be_nil
    end

    it "can post videos to the user's wall without an open file object" do
      result = @api.put_video(cat_movie, content_type)
      @temporary_object_id = result["id"]
      expect(@temporary_object_id).not_to be_nil
    end

    # note: Facebook doesn't post videos immediately to the wall, due to processing time
    # during which get_object(video_id) will return false
    # hence we can't do the same verify test we do for photos
    describe "using aurl instead of a file" do
      let(:url) { "http://techslides.com/demos/sample-videos/small.mp4" }

      it "can post photo to the user's wall using aurl" do
        result = @api.put_video(url)
        @temporary_object_id = result["id"]
        expect(@temporary_object_id).not_to be_nil
      end

      it "can post photo to the user's wall using aurl and an additional param" do
        result = @api.put_video(url, :description => "my message")
        @temporary_object_id = result["id"]
        expect(@temporary_object_id).not_to be_nil
      end
    end
  end

  it "can verify a message with an attachment posted to a feed" do
    attachment = {"name" => "OAuth Playground", "link" => "http://testdomain.koalatest.test/"}
    result = @api.put_wall_post("Hello, world, from the test suite again!", attachment)
    @temporary_object_id = result["id"]
    get_result = @api.get_object(@temporary_object_id)

    # make sure the result we fetch includes all the parameters we sent
    it_matches = attachment.inject(true) {|valid, param| valid && (get_result[param[0]] == attachment[param[0]])}
    expect(it_matches).to be true
  end

  it "can comment on an object" do
    result = @api.put_wall_post("Hello, world, from the test suite, testing comments!")
    @temporary_object_id = result["id"]

    # this will be deleted when the post gets deleted
    comment_result = @api.put_comment(@temporary_object_id, "it's my comment!")
    expect(comment_result).not_to be_nil
  end

  it "can verify a comment posted about an object" do
    message_text = "Hello, world, from the test suite, testing comments again!"
    result = @api.put_wall_post(message_text)
    @temporary_object_id = result["id"]

    # this will be deleted when the post gets deleted
    comment_text = "it's my comment!"
    comment_result = @api.put_comment(@temporary_object_id, comment_text)
    get_result = @api.get_object(comment_result["id"])

    # make sure the text of the comment matches what we sent
    expect(get_result["message"]).to eq(comment_text)
  end

  it "can like an object" do
    result = @api.put_wall_post("Hello, world, from the test suite, testing liking!")
    @temporary_object_id = result["id"]
    app_api = Koala::Facebook::API.new(@app_access_token)
    like_result = app_api.put_like(@temporary_object_id)
    expect(like_result).to be_truthy
  end

  # Page Access Token Support
  describe "#get_page_access_token" do
    it "gets the page object with the access_token field" do
      # we can't test this live since test users (or random real users) can't be guaranteed to have pages to manage
      expect(@api).to receive(:api).with("my_page", hash_including({:fields => "access_token"}), "get", anything).and_return(dummy_response)
      @api.get_page_access_token("my_page")
    end

    it "merges in any other arguments" do
      # we can't test this live since test users (or random real users) can't be guaranteed to have pages to manage
      args = {:a => 3}
      expect(@api).to receive(:api).with("my_page", hash_including(args), "get", anything).and_return(dummy_response)
      @api.get_page_access_token("my_page", args)
    end
  end

  it "can get information about an access token" do
    result = @api.debug_token(KoalaTest.app_access_token)
    expect(result).to be_kind_of(Hash)
    expect(result["data"]).to be_kind_of(Hash)
    expect(result["data"]["app_id"].to_s).to eq(KoalaTest.app_id.to_s)
    expect(result["data"]["application"]).not_to be_nil
  end

  describe "#set_app_restrictions" do
    before :all do
      oauth = Koala::Facebook::OAuth.new(KoalaTest.app_id, KoalaTest.secret)
      app_token = oauth.get_app_access_token
      @app_api = Koala::Facebook::API.new(app_token)
      @restrictions = {"age_distr" => "13+"}
    end

    it "makes a POST to /app_id" do
      expect(@app_api).to receive(:graph_call).with(KoalaTest.app_id, anything, "post", anything)
      @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions)
    end

    it "JSON-encodes the restrictions" do
      expect(@app_api).to receive(:graph_call).with(anything, hash_including(:restrictions => JSON.dump(@restrictions)), anything, anything)
      @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions)
    end

    it "includes the other arguments" do
      args = {:a => 2}
      expect(@app_api).to receive(:graph_call).with(anything, hash_including(args), anything, anything)
      @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions, args)
    end

    it "works" do
      expect(@app_api.set_app_restrictions(KoalaTest.app_id, @restrictions)).to be_truthy
    end
  end

  # test all methods to make sure they pass data through to the API
  # we run the tests here (rather than in the common shared example group)
  # since some require access tokens
  describe "HTTP options" do
    # Each of the below methods should take an options hash as their last argument.
    [
      :get_object,
      :get_connections,
      :put_wall_post,
      :put_comment,
      :put_like,
      :search,
      :set_app_restrictions,
      :get_page_access_token,
      :get_objects
    ].each do |method_name|
      it "passes http options through for #{method_name}" do
        params = @api.method(method_name).parameters
        expect(params.last).to eq([:block, :block])
        expect(params[-2]).to eq([:opt, :options])
      end
    end

    # also test get_picture, which merges a parameter into options
    it "passes http options through for get_picture" do
      options = {:a => 2}
      # graph call should ultimately receive options as the fourth argument
      expect(@api).to receive(:graph_call).with(anything, anything, anything, hash_including(options)).and_return({})
      @api.send(:get_picture, "x", {}, options)
    end
  end

  # Beta tier
  # In theory this is usable by both but so few operations now allow access without a token
  it "can use the beta tier" do
    result = @api.get_object(KoalaTest.user1, {}, :beta => true)
    # the results should have an ID and a name, among other things
    expect(result["id"] && result["name"]).to be_truthy
  end
end


# GraphCollection
shared_examples_for "Koala GraphAPI with GraphCollection" do
  let(:dummy_response) { double("fake response", data: {}, status: 200, body: "", headers: {}) }

  describe "when getting a collection" do
    # GraphCollection methods
    it "gets a GraphCollection when getting connections" do
      @result = @api.get_connections(KoalaTest.page, "events")
      expect(@result).to be_a(Koala::Facebook::API::GraphCollection)
    end

    it "returns nil if the get_collections call fails with nil" do
      # this happens sometimes
      expect(@api).to receive(:graph_call).and_return(nil)
      expect(@api.get_connections(KoalaTest.page, "photos")).to be_nil
    end

    it "gets a GraphCollection when searching" do
      result = @api.search("facebook", type: "page")
      expect(result).to be_a(Koala::Facebook::API::GraphCollection)
    end

    it "returns nil if the search call fails with nil" do
      # this happens sometimes
      expect(@api).to receive(:graph_call).and_return(nil)
      expect(@api.search("facebook", type: "page")).to be_nil
    end

    it "gets a GraphCollection when paging through results" do
      @results = @api.get_page(["search", {"q"=>"facebook", "type" => "page", "limit"=>"25", "until"=> KoalaTest.search_time}])
      expect(@results).to be_a(Koala::Facebook::API::GraphCollection)
    end

    it "returns nil if the page call fails with nil" do
      # this happens sometimes
      expect(@api).to receive(:graph_call).and_return(nil)
      expect(@api.get_page(["search", {"q"=>"facebook", "type" => "page", "limit"=>"25", "until"=> KoalaTest.search_time}])).to be_nil
    end
  end
end


shared_examples_for "Koala GraphAPI without an access token" do
  it "can't get data about 'me'" do
    expect { @api.get_object("me") }.to raise_error(Koala::Facebook::ClientError)
  end

  it "can't access connections from users" do
    expect { @api.get_connections(KoalaTest.user2, "likes") }.to raise_error(Koala::Facebook::ClientError)
  end

  it "can't put an object" do
    expect { @result = @api.put_connections(KoalaTest.user2, "feed", :message => "Hello, world") }.to raise_error(Koala::Facebook::AuthenticationError)
    # legacy put_object syntax
    expect { @result = @api.put_object(KoalaTest.user2, "feed", :message => "Hello, world") }.to raise_error(Koala::Facebook::AuthenticationError)
  end

  # these are not strictly necessary as the other put methods resolve to put_connections,
  # but are here for completeness
  it "can't post to a feed" do
    expect(lambda do
      attachment = {:name => "OAuth Playground", :link => "http://testdomain.koalatest.test/"}
      @result = @api.put_wall_post("Hello, world", attachment, "facebook")
    end).to raise_error(Koala::Facebook::AuthenticationError)
  end

  it "can't comment on an object" do
    # random public post on the facebook wall
    expect { @result = @api.put_comment("7204941866_119776748033392", "The hackathon was great!") }.to raise_error(Koala::Facebook::AuthenticationError)
  end

  it "can't like an object" do
    expect { @api.put_like("7204941866_119776748033392") }.to raise_error(Koala::Facebook::AuthenticationError)
  end

  # DELETE
  it "can't delete posts" do
    # test post on the Ruby SDK Test application
    expect { @result = @api.delete_object("115349521819193_113815981982767") }.to raise_error(Koala::Facebook::AuthenticationError)
  end

  it "can't delete a like" do
    expect { @api.delete_like("7204941866_119776748033392") }.to raise_error(Koala::Facebook::AuthenticationError)
  end
end

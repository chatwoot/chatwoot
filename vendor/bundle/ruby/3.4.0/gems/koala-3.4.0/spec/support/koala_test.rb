# small helper method for live testing
module KoalaTest

  class << self
    attr_accessor :oauth_token, :app_id, :secret, :app_access_token, :code, :session_key
    attr_accessor :oauth_test_data, :subscription_test_data, :search_time
    attr_accessor :test_user_api
    attr_accessor :vcr_oauth_token
  end

  # Test setup

  def self.setup_test_environment!
    setup_rspec

    if live?
      # Runs Koala specs through the Facebook servers
      # using data for a real app
      live_data = YAML.load_file(File.join(File.dirname(__FILE__), '../fixtures/facebook_data.yml'))
      KoalaTest.setup_test_data(live_data)

      activate_adapter!

      Koala.http_service.http_options[:beta] = true if ENV["beta"] || ENV["BETA"]

      # use a test user unless the developer wants to test against a real profile
      unless token = KoalaTest.oauth_token
        KoalaTest.setup_test_users
      else
        KoalaTest.validate_user_info(token)
      end
    else
      # By default the Koala specs are run using stubs for HTTP requests,
      # so they won't fail due to Facebook-imposed rate limits or server timeouts.
      #
      # However as a result they are more brittle since
      # we are not testing the latest responses from the Facebook servers.
      # To be certain all specs pass with the current Facebook services,
      # run LIVE=true bundle exec rake spec.
      activate_vcr!
      Koala.http_service = Koala::MockHTTPService
      KoalaTest.setup_test_data(Koala::MockHTTPService::TEST_DATA)
    end
  end

  def self.setup_rspec
    # set up a global before block to set the token for tests
    # set the token up for
    RSpec.configure do |config|
      config.before :each do
        @token = KoalaTest.oauth_token
        allow(Koala::Utils).to receive(:deprecate) # never fire deprecation warnings
        # Clean up Koala config
        Koala.reset_config
      end

      config.after :each do
        # if we're working with a real user, clean up any objects posted to Facebook
        # no need to do so for test users, since they get deleted at the end
        if @temporary_object_id && KoalaTest.real_user?
          raise "Unable to locate API when passed temporary object to delete!" unless @api

          # wait 10ms to allow Facebook to propagate data so we can delete it
          sleep(0.01)

          # clean up any objects we've posted
          result = (@api.delete_object(@temporary_object_id) rescue false)
          # if we errored out or Facebook returned false, track that
          puts "Unable to delete #{@temporary_object_id}: #{result} (probably a photo or video, which can't be deleted through the API)" unless result
        end

      end
    end
  end

  # If we're running live tests against the Facebook API, don't use the VCR
  # fixtures. (Another alternative would be to rerecord those fixtures, but we
  # don't necessarily want to do that.
  def self.with_vcr_unless_live(name)
    if live?
      yield
    else
      begin
        # if we're using VCR, we don't want to use the mock service, which was
        # an early implementation of the same type of tool
        old_adapter = Koala.http_service
        Koala.http_service = Koala::HTTPService
        activate_adapter!
        VCR.use_cassette(name) do
          yield
        end
      ensure
        Koala.http_service = old_adapter
      end
    end
  end

  def self.setup_test_data(data)
    # make data accessible to all our tests
    self.oauth_test_data = data["oauth_test_data"]
    self.subscription_test_data = data["subscription_test_data"]
    self.oauth_token = data["oauth_token"]
    self.app_id = data["oauth_test_data"]["app_id"].to_s
    self.app_access_token = data["oauth_test_data"]["app_access_token"]
    self.secret = data["oauth_test_data"]["secret"]
    self.code = data["oauth_test_data"]["code"]
    self.session_key = data["oauth_test_data"]["session_key"]

    # fix the search time so it can be used in the mock responses
    self.search_time = data["search_time"] || (Time.now - 3600).to_s
  end

  def self.testing_permissions
    "read_stream, publish_actions, user_photos, user_videos, read_insights"
  end

  def self.setup_test_users
    print "Setting up test users..."
    @test_user_api = Koala::Facebook::TestUsers.new(:app_id => self.app_id, :secret => self.secret)

    RSpec.configure do |config|
      config.before :suite do
        # before each test module, create two test users with specific names and befriend them
        KoalaTest.create_test_users
      end

      config.after :suite do
        # after each test module, delete the test users to avoid cluttering up the application
        KoalaTest.destroy_test_users
      end
    end

    puts "done."
  end

  def self.create_test_users
    begin
      @live_testing_user = @test_user_api.create(true, KoalaTest.testing_permissions, :name => KoalaTest.user1_name)
      @live_testing_friend = @test_user_api.create(true, KoalaTest.testing_permissions, :name => KoalaTest.user2_name)
      @test_user_api.befriend(@live_testing_user, @live_testing_friend)
      self.oauth_token = @live_testing_user["access_token"]
    rescue Exception => e
      Kernel.warn("Problem creating test users! #{e.message}")
      raise
    end
  end

  def self.destroy_test_users
    [@live_testing_user, @live_testing_friend].each do |u|
      puts "Unable to delete test user #{u.inspect}" if u && !(@test_user_api.delete(u) rescue false)
    end
  end

  def self.validate_user_info(token)
    print "Validating permissions for live testing..."
    # make sure we have the necessary permissions
    api = Koala::Facebook::API.new(token)
    perms = api.get_connect("me", "permissions")["data"]

    # live testing depends on insights calls failing
    if perms.keys.include?("read_insights") || (perms.keys & testing_permissions) != testing_permissions
      puts "failed!\n" # put a new line after the print above
      raise ArgumentError, "Your access token must have #{testing_permissions.join(", ")}, and lack read_insights.  You have: #{perms.inspect}"
    end
    puts "done!"
  end

  # Info about the testing environment
  def self.real_user?
    !(mock_interface? || @test_user_api)
  end

  def self.test_user?
    !!@test_user_api
  end

  def self.mock_interface?
    Koala.http_service == Koala::MockHTTPService
  end

  # Data for testing
  def self.user1
    # user ID, either numeric or username
    test_user? ? @live_testing_user["id"] : "barackobama"
  end

  def self.user1_id
    # numerical ID, used for FQL
    # (otherwise the two IDs are interchangeable)
    test_user? ? @live_testing_user["id"] : 2905623
  end

  def self.user1_name
    "Alex"
  end

  def self.user2
    # see notes for user1
    test_user? ? @live_testing_friend["id"] : "koppel"
  end

  def self.user2_id
    # see notes for user1
    test_user? ? @live_testing_friend["id"] : 2901279
  end

  def self.user2_name
    "Luke"
  end

  def self.page
    "facebook"
  end

  def self.app_properties
    mock_interface? ? {"desktop" => 0} : {"description" => "A test framework for Koala and its users.  (#{rand(10000).to_i})"}
  end

  def self.live?
    ENV['LIVE']
  end

  def self.activate_vcr!
    require 'vcr'

    VCR.configure do |c|
      c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
      c.hook_into :webmock # or :fakeweb
      c.ignore_hosts 'codeclimate.com' # Allow test coverage to be reported
    end
  end

  def self.activate_adapter!
    unless @adapter_activation_attempted
      # allow live tests with different adapters
      adapter = ENV['ADAPTER'] || "typhoeus" # use Typhoeus by default if available
      begin
        # JRuby doesn't support typhoeus on Travis
        unless defined? JRUBY_VERSION
          require adapter
          require "faraday/#{adapter}"
          Faraday.default_adapter = adapter.to_sym
        end
      rescue => e
        puts "Unable to load adapter #{adapter}, using Net::HTTP. #{e.class} #{e.message}"
      ensure
        @adapter_activation_attempted = true
      end
    end
  end
end

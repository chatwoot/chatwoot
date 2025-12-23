require 'koala'

module Koala
  module Facebook

    # Create and manage test users for your application.
    # A test user is a user account associated with an app created for the purpose
    # of testing the functionality of that app.
    # You can use test users for manual or automated testing --
    # Koala's live test suite uses test users to verify the library works with Facebook.
    #
    # @note the test user API is fairly slow compared to other interfaces
    #       (which makes sense -- it's creating whole new user accounts!).
    #
    # See http://developers.facebook.com/docs/test_users/.
    class TestUsers
      # The application API interface used to communicate with Facebook.
      # @return [Koala::Facebook::API]
      attr_reader :api
      attr_reader :app_id, :app_access_token, :secret

      # Create a new TestUsers instance.
      # If you don't have your app's access token, provide the app's secret and
      # Koala will make a request to Facebook for the appropriate token.
      #
      # @param options initialization options.
      # @option options :app_id the application's ID.
      # @option options :app_access_token an application access token, if known.
      # @option options :secret the application's secret.
      #
      # @raise ArgumentError if the application ID and one of the app access token or the secret are not provided.
      def initialize(options = {})
        @app_id = options[:app_id] || Koala.config.app_id
        @app_access_token = options[:app_access_token] || Koala.config.app_access_token
        @secret = options[:secret] || Koala.config.app_secret

        unless @app_id && (@app_access_token || @secret) # make sure we have what we need
          raise ArgumentError, "Initialize must receive a hash with :app_id and either :app_access_token or :secret! (received #{options.inspect})"
        end

        # fetch the access token if we're provided a secret
        if @secret && !@app_access_token
          oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
          @app_access_token = oauth.get_app_access_token
        end

        @api = API.new(@app_access_token)
      end

      # Create a new test user.
      #
      # @param installed whether the user has installed your app
      # @param permissions a comma-separated string or array of permissions the user has granted (if installed)
      # @param args any additional arguments for the create call (name, etc.)
      # @param options (see Koala::Facebook::API#api)
      #
      # @return a hash of information for the new user (id, access token, login URL, etc.)
      def create(installed, permissions = nil, args = {}, options = {})
        # Creates and returns a test user
        args['installed'] = installed
        args['permissions'] = (permissions.is_a?(Array) ? permissions.join(",") : permissions) if installed
        @api.graph_call(test_user_accounts_path, args, "post", options)
      end

      # List all test users for the app.
      #
      # @param options (see Koala::Facebook::API#api)
      #
      # @return an array of hashes of user information (id, access token, etc.)
      def list(options = {})
        @api.graph_call(test_user_accounts_path, {}, "get", options)
      end

      # Delete a test user.
      #
      # @param test_user the user to delete; can be either a Facebook ID or the hash returned by {#create}
      # @param options (see Koala::Facebook::API#api)
      #
      # @return true if successful, false (or an {Koala::Facebook::APIError APIError}) if not
      def delete(test_user, options = {})
        test_user = test_user["id"] if test_user.is_a?(Hash)
        @api.delete_object(test_user, options)
      end

      # Deletes all test users in batches of 50.
      #
      # @note if you have a lot of test users (> 20), this operation can take a long time.
      #
      # @param options (see Koala::Facebook::API#api)
      #
      # @return a list of the test users that have been deleted
      def delete_all(options = {})
        # ideally we'd save a call by checking next_page_params, but at the time of writing
        # Facebook isn't consistently returning full pages after the first one
        previous_list = nil
        while (test_user_list = list(options)).length > 0
          # avoid infinite loops if Facebook returns buggy users you can't delete
          # see http://developers.facebook.com/bugs/223629371047398
          # since the hashes may change across calls, even if the IDs don't,
          # we just compare the IDs.
          test_user_ids = test_user_list.map {|u| u['id']}
          previous_user_ids = (previous_list || []).map {|u| u['id']}
          break if (test_user_ids - previous_user_ids).empty?

          test_user_list.each_slice(50) do |users|
            self.api.batch(options) {|batch_api| users.each {|u| batch_api.delete_object(u["id"]) }}
          end

          previous_list = test_user_list
        end
      end

      # Updates a test user's attributes.
      #
      # @note currently, only name and password can be changed;
      #       see {http://developers.facebook.com/docs/test_users/ the Facebook documentation}.
      #
      # @param test_user the user to update; can be either a Facebook ID or the hash returned by {#create}
      # @param args the updates to make
      # @param options (see Koala::Facebook::API#api)
      #
      # @return true if successful, false (or an {Koala::Facebook::APIError APIError}) if not
      def update(test_user, args = {}, options = {})
        test_user = test_user["id"] if test_user.is_a?(Hash)
        @api.graph_call(test_user, args, "post", options)
      end

      # Make two test users friends.
      #
      # @note there's no way to unfriend test users; you can always just create a new one.
      #
      # @param user1_hash one of the users to friend; the hash must contain both ID and access token (as returned by {#create})
      # @param user2_hash the other user to friend
      # @param options (see Koala::Facebook::API#api)
      #
      # @return true if successful, false (or an {Koala::Facebook::APIError APIError}) if not
      def befriend(user1_hash, user2_hash, options = {})
        user1_id = user1_hash["id"] || user1_hash[:id]
        user2_id = user2_hash["id"] || user2_hash[:id]
        user1_token = user1_hash["access_token"] || user1_hash[:access_token]
        user2_token = user2_hash["access_token"] || user2_hash[:access_token]
        unless user1_id && user2_id && user1_token && user2_token
          # we explicitly raise an error here to minimize the risk of confusing output
          # if you pass in a string (as was previously supported) no local exception would be raised
          # but the Facebook call would fail
          raise ArgumentError, "TestUsers#befriend requires hash arguments for both users with id and access_token"
        end

        u1_graph_api = API.new(user1_token, secret)
        u2_graph_api = API.new(user2_token, secret)

        # if we have a secret token, flag that we want the appsecret_proof to be generated
        u1_graph_api.graph_call("#{user1_id}/friends/#{user2_id}", {}, "post", options.merge(appsecret_proof: !!secret)) &&
          u2_graph_api.graph_call("#{user2_id}/friends/#{user1_id}", {}, "post", options.merge(appsecret_proof: !!secret))
      end

      # Create a network of test users, all of whom are friends and have the same permissions.
      #
      # @note this call slows down dramatically the more users you create
      #       (test user calls are slow, and more users => more 1-on-1 connections to be made).
      #       Use carefully.
      #
      # @param network_size how many users to create
      # @param installed whether the users have installed your app (see {#create})
      # @param permissions what permissions the users have granted (see {#create})
      # @param options (see Koala::Facebook::API#api)
      #
      # @return the list of users created
      def create_network(network_size, installed = true, permissions = '', options = {})
        users = (0...network_size).collect { create(installed, permissions, {}, options) }
        friends = users.clone
        users.each do |user|
          # Remove this user from list of friends
          friends.delete_at(0)
          # befriend all the others
          friends.each do |friend|
            befriend(user, friend, options)
          end
        end
        return users
      end

      # The Facebook test users management URL for your application.
      def test_user_accounts_path
        @test_user_accounts_path ||= "/#{@app_id}/accounts/test-users"
      end
    end # TestUserMethods
  end # Facebook
end # Koala

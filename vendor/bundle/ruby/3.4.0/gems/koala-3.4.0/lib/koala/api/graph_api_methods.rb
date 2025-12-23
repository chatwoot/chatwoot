require 'addressable/uri'

require 'koala/api/graph_collection'
require 'koala/http_service/uploadable_io'
require 'koala/api/graph_error_checker'

module Koala
  module Facebook
    # Methods used to interact with the Facebook Graph API.
    #
    # See https://github.com/arsduo/koala/wiki/Graph-API for a general introduction to Koala
    # and the Graph API.
    #
    # The Graph API is made up of the objects in Facebook (e.g., people, pages,
    # events, photos, etc.) and the connections between them (e.g., friends,
    # photo tags, event RSVPs, etc.). Koala provides access to those
    # objects types in a generic way. For example, given an OAuth access
    # token, this will fetch the profile of the active user and the list
    # of the user's friends:
    #
    # @example
    #         graph = Koala::Facebook::API.new(access_token)
    #         user = graph.get_object("me")
    #         friends = graph.get_connections(user["id"], "friends")
    #
    # You can see a list of all of the objects and connections supported
    # by the API at http://developers.facebook.com/docs/reference/api/.
    #
    # You can obtain an access token via OAuth or by using the Facebook JavaScript SDK.
    # If you're using the JavaScript SDK, you can use the
    # {Koala::Facebook::OAuth#get_user_from_cookie} method to get the OAuth access token
    # for the active user from the cookie provided by Facebook.
    # See the Koala and Facebook documentation for more information.
    module GraphAPIMethods
      # Objects

      # Get information about a Facebook object.
      #
      # @param id the object ID (string or number)
      # @param args any additional arguments
      #         (fields, metadata, etc. -- see {http://developers.facebook.com/docs/reference/api/ Facebook's documentation})
      # @param options (see Koala::Facebook::API#api)
      # @param block for post-processing. It receives the result data; the
      #        return value of the method is the result of the block, if
      #        provided.  (see Koala::Facebook::API#api)
      #
      # @raise [Koala::Facebook::APIError] if the ID is invalid or you don't have access to that object
      #
      # @example
      #     get_object("me")  # => {"id" => ..., "name" => ...}
      #     get_object("me") {|data| data['education']}  # => only education section of profile
      #
      # @return a hash of object data
      def get_object(id, args = {}, options = {}, &block)
        # Fetches the given object from the graph.
        graph_call(id, args, "get", options, &block)
      end

      # Get the metadata of a Facebook object, including its type.
      #
      # @param id the object ID (string or number)
      #
      # @raise [Koala::Facebook::ClientError] if the ID is invalid
      # @example
      #     get_object_metadata("442575165800306")=>{"metadata" => "page", ...}
      #     get_object_metadata("190822584430113")=>{"metadata" => "status", ...}
      # @return a string of Facebook object type
      def get_object_metadata(id, &block)
        result = graph_call(id, {"metadata" => "1"}, "get", {}, &block)
        result["metadata"]
      end

      # Get information about multiple Facebook objects in one call.
      #
      # @param ids an array or comma-separated string of object IDs
      # @param args (see #get_object)
      # @param options (see Koala::Facebook::API#api)
      # @param block (see Koala::Facebook::API#api)
      #
      # @raise [Koala::Facebook::APIError] if any ID is invalid or you don't have access to that object
      #
      # @return an array of object data hashes
      def get_objects(ids, args = {}, options = {}, &block)
        # Fetches all of the given objects from the graph.
        # If any of the IDs are invalid, they'll raise an exception.
        return [] if ids.empty?
        graph_call("", args.merge("ids" => ids.respond_to?(:join) ? ids.join(",") : ids), "get", options, &block)
      end

      # Write an object to the Graph for a specific user.
      # @see #put_connections
      #
      # @note put_object is (for historical reasons) the same as put_connections.
      #       Please use put_connections; in a future version of Koala (2.0?),
      #       put_object will issue a POST directly to an individual object, not to a connection.
      def put_object(parent_object, connection_name, args = {}, options = {}, &block)
        put_connections(parent_object, connection_name, args, options, &block)
      end

      # Delete an object from the Graph if you have appropriate permissions.
      #
      # @param id (see #get_object)
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return true if successful, false (or an APIError) if not
      def delete_object(id, options = {}, &block)
        # Deletes the object with the given ID from the graph.
        raise AuthenticationError.new(nil, nil, "Delete requires an access token") unless access_token
        graph_call(id, {}, "delete", options, &block)
      end

      # Fetch information about a given connection (e.g. type of activity -- feed, events, photos, etc.)
      # for a specific user.
      # See {http://developers.facebook.com/docs/api Facebook's documentation} for a complete list of connections.
      #
      # @note to access connections like /user_id/CONNECTION/other_user_id,
      #       simply pass "CONNECTION/other_user_id" as the connection_name
      #
      # @param id (see #get_object)
      # @param connection_name what
      # @param args any additional arguments
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return [Koala::Facebook::API::GraphCollection] an array of object hashes (in most cases)
      def get_connection(id, connection_name, args = {}, options = {}, &block)
        # Fetches the connections for given object.
        graph_call("#{id}/#{connection_name}", args, "get", options, &block)
      end
      alias_method :get_connections, :get_connection


      # Write an object to the Graph for a specific user.
      # See {http://developers.facebook.com/docs/api#publishing Facebook's documentation}
      # for all the supported writeable objects. It is important to note that objects
      # take the singular form, i.e. "event" when using put_connections.
      #
      # @note (see #get_connection)
      #
      # @example
      #         graph.put_connections("me", "feed", :message => "Hello, world")
      #         => writes "Hello, world" to the active user's wall
      #
      # Most write operations require extended permissions. For example,
      # publishing wall posts requires the "publish_stream" permission. See
      # http://developers.facebook.com/docs/authentication/ for details about
      # extended permissions.
      #
      # @param id (see #get_object)
      # @param connection_name (see #get_connection)
      # @param args (see #get_connection)
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return a hash containing the new object's id
      def put_connections(id, connection_name, args = {}, options = {}, &block)
        # Posts a certain connection
        raise AuthenticationError.new(nil, nil, "Write operations require an access token") unless access_token

        graph_call("#{id}/#{connection_name}", args, "post", options, &block)
      end

      # Delete an object's connection (for instance, unliking the object).
      #
      # @note (see #get_connection)
      #
      # @param id (see #get_object)
      # @param connection_name (see #get_connection)
      # @args (see #get_connection)
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return (see #delete_object)
      def delete_connections(id, connection_name, args = {}, options = {}, &block)
        # Deletes a given connection
        raise AuthenticationError.new(nil, nil, "Delete requires an access token") unless access_token
        graph_call("#{id}/#{connection_name}", args, "delete", options, &block)
      end

      # Fetches a photo url.
      # Note that this method returns the picture url, not the full API
      # response. For the hash containing the full metadata for the photo, use
      # #get_user_picture_data instead.
      #
      # @param options options for Facebook (see #get_object).
      #                        To get a different size photo, pass :type => size (small, normal, large, square).
      # @param block (see Koala::Facebook::API#api)
      #
      # @note to delete photos or videos, use delete_object(id)
      #
      # @return the URL to the image
      def get_picture(object, args = {}, options = {}, &block)
        Koala::Utils.deprecate("API#get_picture will be removed in a future version. Please use API#get_picture_data, which returns a hash including the url.")

        get_user_picture_data(object, args, options) do |result|
          # Try to extract the URL
          result = result.fetch('data', {})['url'] if result.respond_to?(:fetch)
          block ? block.call(result) : result
        end
      end

      # Fetches a photo data hash.
      #
      # @param args (see #get_object)
      # @param options (see Koala::Facebook::API#api)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return a hash of object data
      def get_picture_data(object, args = {}, options = {}, &block)
        # The default response for a Graph API query like GET /me/picture is to
        # return a 302 redirect. This is a surprising difference from the
        # common return type, so we add the `redirect: false` parameter to get
        # a RESTful API response instead.
        args = args.merge(:redirect => false)
        graph_call("#{object}/picture", args, "get", options, &block)
      end

      def get_user_picture_data(*args, &block)
        Koala::Utils.deprecate("API#get_user_picture_data is deprecated and will be removed in a future version. Please use API#get_picture_data, which has the same signature.")
        get_picture_data(*args, &block)
      end

      # Upload a photo.
      #
      # This can be called in multiple ways:
      #   put_picture(file, [content_type], ...)
      #   put_picture(path_to_file, [content_type], ...)
      #   put_picture(picture_url, ...)
      #
      # You can also pass in uploaded files directly from Rails or Sinatra.
      # See {https://github.com/arsduo/koala/wiki/Uploading-Photos-and-Videos the Koala wiki} for more information.
      #
      # @param args (see #get_object)
      # @param target_id the Facebook object to which to post the picture (default: "me")
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @example
      #     put_picture(file, content_type, {:message => "Message"}, 01234560)
      #     put_picture(params[:file], {:message => "Message"})
      #     # with URLs, there's no optional content type field
      #     put_picture(picture_url, {:message => "Message"}, my_page_id)
      #
      # @note to access the media after upload, you'll need the user_photos or user_videos permission as appropriate.
      #
      # @return (see #put_connections)
      def put_picture(*picture_args, &block)
        put_connections(*parse_media_args(picture_args, "photos"), &block)
      end

      # Upload a video.  Functions exactly the same as put_picture (URLs supported as of Facebook
      # API version 2.3).
      # @see #put_picture
      def put_video(*video_args, &block)
        args = parse_media_args(video_args, "videos")
        args.last[:video] = true
        put_connections(*args, &block)
      end

      # Write directly to the user's wall.
      # Convenience method equivalent to put_connections(id, "feed").
      #
      # To get wall posts, use get_connections(user, "feed")
      # To delete a wall post, use delete_object(post_id)
      #
      # @param message the message to write for the wall
      # @param attachment a hash describing the wall post
      #         (see the {https://developers.facebook.com/docs/guides/attachments/ stream attachments} documentation.)
      #         If attachment contains a properties key, this will be turned to
      #         JSON (if it's a hash) since Facebook's API, oddly, requires
      #         this.
      # @param target_id the target wall
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @example
      #       @api.put_wall_post("Hello there!", {
      #         "name" => "Link name",
      #         "link" => "http://www.example.com/",
      #         "caption" => "{*actor*} posted a new review",
      #         "description" => "This is a longer description of the attachment",
      #         "picture" => "http://www.example.com/thumbnail.jpg"
      #       })
      #
      # @see #put_connections
      # @return (see #put_connections)
      def put_wall_post(message, attachment = {}, target_id = "me", options = {}, &block)
        if properties = attachment.delete(:properties) || attachment.delete("properties")
          properties = JSON.dump(properties) if properties.is_a?(Hash) || properties.is_a?(Array)
          attachment["properties"] = properties
        end
        put_connections(target_id, "feed", attachment.merge({:message => message}), options, &block)
      end

      # Comment on a given object.
      # Convenience method equivalent to put_connection(id, "comments").
      #
      # To delete comments, use delete_object(comment_id).
      # To get comments, use get_connections(object, "likes").
      #
      # @param id (see #get_object)
      # @param message the comment to write
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return (see #put_connections)
      def put_comment(id, message, options = {}, &block)
        # Writes the given comment on the given post.
        put_connections(id, "comments", {:message => message}, options, &block)
      end

      # Like a given object.
      # Convenience method equivalent to put_connections(id, "likes").
      #
      # To get a list of a user's or object's likes, use get_connections(id, "likes").
      #
      # @param id (see #get_object)
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return (see #put_connections)
      def put_like(id, options = {}, &block)
        # Likes the given post.
        put_connections(id, "likes", {}, options, &block)
      end

      # Unlike a given object.
      # Convenience method equivalent to delete_connection(id, "likes").
      #
      # @param id (see #get_object)
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return (see #delete_object)
      def delete_like(id, options = {}, &block)
        # Unlikes a given object for the logged-in user
        raise AuthenticationError.new(nil, nil, "Unliking requires an access token") unless access_token
        graph_call("#{id}/likes", {}, "delete", options, &block)
      end

      # Search for a given query among visible Facebook objects.
      # See {http://developers.facebook.com/docs/reference/api/#searching Facebook documentation} for more information.
      #
      # @param search_terms the query to search for
      # @param args object type and any additional arguments, such as fields, etc.
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return [Koala::Facebook::API::GraphCollection] an array of search results
      def search(search_terms, args = {}, options = {}, &block)
        # Normally we wouldn't enforce Facebook API behavior, but the API fails with cryptic error
        # messages if you fail to include a type term. For a convenience method, that is valuable.
        raise ArgumentError, "type must be includedin args when searching" unless args[:type] || args["type"]
        graph_call("search", args.merge("q" => search_terms), "get", options, &block)
      end

      # Convenience Methods
      # In general, we're trying to avoid adding convenience methods to Koala
      # except to support cases where the Facebook API requires non-standard input
      # such as JSON-encoding arguments, posts directly to objects, etc.

      # Get a page's access token, allowing you to act as the page.
      # Convenience method for @api.get_object(page_id, :fields => "access_token").
      #
      # @param id the page ID
      # @param args (see #get_object)
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      #
      # @return the page's access token (discarding expiration and any other information)
      def get_page_access_token(id, args = {}, options = {}, &block)
        access_token = get_object(id, args.merge(:fields => "access_token"), options) do |result|
          result ? result["access_token"] : nil
        end

        block ? block.call(access_token) : access_token
      end

      # Get an access token information
      # The access token used to instantiate the API object needs to be
      # the app access token or a valid User Access Token from a developer of the app.
      # See https://developers.facebook.com/docs/howtos/login/debugging-access-tokens/#step1
      #
      # @param input_token the access token you want to inspect
      # @param block (see Koala::Facebook::API#api)
      #
      # @return a JSON array containing data and a map of fields
      def debug_token(input_token, &block)
        access_token_info = graph_call("debug_token", {:input_token => input_token})

        block ? block.call(access_token_info) : access_token_info
      end

      # App restrictions require you to JSON-encode the restriction value. This
      # is neither obvious nor intuitive, so this convenience method is
      # provided.
      #
      # @params app_id the application to apply the restrictions to
      # @params restrictions_hash the restrictions to apply
      # @param args (see #get_object)
      # @param options (see #get_object)
      # @param block (see Koala::Facebook::API#api)
      def set_app_restrictions(app_id, restrictions_hash, args = {}, options = {}, &block)
        graph_call(app_id, args.merge(:restrictions => JSON.dump(restrictions_hash)), "post", options, &block)
      end

      # Certain calls such as {#get_connections} return an array of results which you can page through
      # forwards and backwards (to see more feed stories, search results, etc.).
      # Those methods use get_page to request another set of results from Facebook.
      #
      # @note You'll rarely need to use this method unless you're using Sinatra or another non-Rails framework
      #       (see {Koala::Facebook::API::GraphCollection GraphCollection} for more information).
      #
      # @param params an array of arguments to graph_call
      #               as returned by {Koala::Facebook::API::GraphCollection.parse_page_url}.
      # @param block (see Koala::Facebook::API#api)
      #
      # @return Koala::Facebook::API::GraphCollection the appropriate page of results (an empty array if there are none)
      def get_page(params, &block)
        graph_call(*params, &block)
      end

      # Execute a set of Graph API calls as a batch.
      # See {https://github.com/arsduo/koala/wiki/Batch-requests batch request documentation}
      # for more information and examples.
      #
      # @param http_options HTTP options for the entire request.
      #
      # @yield batch_api [Koala::Facebook::GraphBatchAPI] an API subclass
      #                  whose requests will be queued and executed together at the end of the block
      #
      # @raise [Koala::Facebook::APIError] only if there is a problem with the overall batch request
      #                                    (e.g. connectivity failure, an operation with a missing dependency).
      #                                    Individual calls that error out will be represented as an unraised
      #                                    APIError in the appropriate spot in the results array.
      #
      # @example
      #         results = @api.batch do |batch_api|
      #           batch_api.get_object('me')
      #           batch_api.get_object(KoalaTest.user1)
      #         end
      #         # => [{'id' => my_id, ...}, {'id' => koppel_id, ...}]
      #
      #         # You can also provide blocks to your operations to process the
      #         # results, which is often useful if you're constructing batch
      #         # requests in various locations and want to keep the code
      #         # together in logical places.
      #         # See readme.md and the wiki for more examples.
      #         @api.batch do |batch_api|
      #           batch_api.get_object('me') {|data| data["id"] }
      #           batch_api.get_object(KoalaTest.user1) {|data| data["name"] }
      #         end
      #         # => [my_id, "Alex Koppel"]
      #
      # @return an array of results from your batch calls (as if you'd made them individually),
      #         arranged in the same order they're made.
      def batch(http_options = {}, &block)
        batch_client = GraphBatchAPI.new(self)
        if block
          yield batch_client
          batch_client.execute(http_options)
        else
          batch_client
        end
      end

      private

      def parse_media_args(media_args, method)
        # photo and video uploads can accept different types of arguments (see above)
        # so here, we parse the arguments into a form directly usable in put_connections
        raise KoalaError.new("Wrong number of arguments for put_#{method == "photos" ? "picture" : "video"}") unless media_args.size.between?(1, 5)

        args_offset = media_args[1].kind_of?(Hash) || media_args.size == 1 ? 0 : 1

        args      = media_args[1 + args_offset] || {}
        target_id = media_args[2 + args_offset] || "me"
        options   = media_args[3 + args_offset] || {}

        if url?(media_args.first)
          # If media_args is a URL, we can upload without UploadableIO
          # Video: https://developers.facebook.com/docs/graph-api/video-uploads
          fb_expected_arg_name = method == "photos" ? :url : :file_url
          args.merge!(fb_expected_arg_name => media_args.first)
        else
          args["source"] = Koala::HTTPService::UploadableIO.new(*media_args.slice(0, 1 + args_offset))
        end

        [target_id, method, args, options]
      end

      def url?(data)
        return false unless data.is_a? String
        begin
          uri = Addressable::URI.parse(data)
          %w( http https ).include?(uri.scheme)
        rescue Addressable::URI::InvalidURIError
          false
        end
      end
    end
  end
end

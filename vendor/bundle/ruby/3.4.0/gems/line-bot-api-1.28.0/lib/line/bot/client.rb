# Copyright 2016 LINE
#
# LINE Corporation licenses this file to you under the Apache License,
# version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

require 'base64'
require 'net/http'
require 'openssl'
require 'uri'

module Line
  module Bot
    # API Client of LINE Bot SDK Ruby
    #
    #   @client ||= Line::Bot::Client.new do |config|
    #     config.channel_id = ENV["LINE_CHANNEL_ID"]
    #     config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    #     config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    #   end
    class Client
      #  @return [String]
      attr_accessor :channel_token, :channel_id, :channel_secret, :endpoint, :blob_endpoint

      # @return [Object]
      attr_accessor :httpclient

      # @return [Hash]
      attr_accessor :http_options

      # Initialize a new client.
      #
      # @param options [Hash]
      # @return [Line::Bot::Client]
      def initialize(options = {})
        options.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
        yield(self) if block_given?
      end

      def httpclient
        @httpclient ||= HTTPClient.new(http_options)
      end

      def endpoint
        @endpoint ||= API::DEFAULT_ENDPOINT
      end

      def oauth_endpoint
        @oauth_endpoint ||= API::DEFAULT_OAUTH_ENDPOINT
      end

      def blob_endpoint
        return @blob_endpoint if @blob_endpoint

        @blob_endpoint = if endpoint == API::DEFAULT_ENDPOINT
                           API::DEFAULT_BLOB_ENDPOINT
                         else
                           # for backward compatible
                           endpoint
                         end
      end

      def liff_endpoint
        @liff_endpoint ||= API::DEFAULT_LIFF_ENDPOINT
      end

      # @return [Hash]
      def credentials
        {
          "Authorization" => "Bearer #{channel_token}",
        }
      end

      # Issue channel access token
      #
      # @param grant_type [String] Grant type
      #
      # @return [Net::HTTPResponse]
      def issue_channel_token(grant_type = 'client_credentials')
        channel_id_required
        channel_secret_required

        endpoint_path = '/oauth/accessToken'
        payload = URI.encode_www_form(
          grant_type:    grant_type,
          client_id:     channel_id,
          client_secret: channel_secret
        )
        headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
        post(endpoint, endpoint_path, payload, headers)
      end

      # Revoke channel access token
      #
      # @return [Net::HTTPResponse]
      def revoke_channel_token(access_token)
        endpoint_path = '/oauth/revoke'
        payload = URI.encode_www_form(access_token: access_token)
        headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
        post(endpoint, endpoint_path, payload, headers)
      end

      # Issue channel access token v2.1
      #
      # @param jwt [String]
      #
      # @return [Net::HTTPResponse]
      def issue_channel_access_token_jwt(jwt)
        endpoint_path = '/oauth2/v2.1/token'
        payload = URI.encode_www_form(
          grant_type: 'client_credentials',
          client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
          client_assertion: jwt
        )
        headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
        post(oauth_endpoint, endpoint_path, payload, headers)
      end

      # Revoke channel access token v2.1
      #
      # @param access_token [String]
      #
      # @return [Net::HTTPResponse]
      def revoke_channel_access_token_jwt(access_token)
        channel_id_required
        channel_secret_required

        endpoint_path = '/oauth2/v2.1/revoke'
        payload = URI.encode_www_form(
          client_id: channel_id,
          client_secret: channel_secret,
          access_token: access_token
        )
        headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
        post(oauth_endpoint, endpoint_path, payload, headers)
      end

      # Verify ID token
      #
      # @param id_token [String] ID token
      # @param nonce [String] Expected nonce value. Use the nonce value provided in the authorization request. Omit if the nonce value was not specified in the authorization request.
      # @param user_id [String] Expected user ID.
      #
      # @return [Net::HTTPResponse]
      def verify_id_token(id_token, nonce: nil, user_id: nil)
        channel_id_required

        endpoint_path = '/oauth2/v2.1/verify'
        payload = URI.encode_www_form({
          client_id: channel_id,
          id_token: id_token,
          nonce: nonce,
          user_id: user_id
        }.compact)
        headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
        post(oauth_endpoint, endpoint_path, payload, headers)
      end

      # Verify access token v2.1
      #
      # @param access_token [String] access token
      #
      # @return [Net::HTTPResponse]
      def verify_access_token(access_token)
        payload = URI.encode_www_form(
          access_token: access_token
        )
        endpoint_path = "/oauth2/v2.1/verify?#{payload}"
        get(oauth_endpoint, endpoint_path)
      end

      # Get all valid channel access token key IDs v2.1
      #
      # @param jwt [String]
      #
      # @return [Net::HTTPResponse]
      def get_channel_access_token_key_ids_jwt(jwt)
        payload = URI.encode_www_form(
          client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
          client_assertion: jwt
        )
        endpoint_path = "/oauth2/v2.1/tokens/kid?#{payload}"

        headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
        get(oauth_endpoint, endpoint_path, headers)
      end

      # Get user profile by access token
      #
      # @param access_token [String] access token
      #
      # @return [Net::HTTPResponse]
      def get_profile_by_access_token(access_token)
        headers = {
          "Authorization" => "Bearer #{access_token}",
        }
        endpoint_path = "/v2/profile"
        get(oauth_endpoint, endpoint_path, headers)
      end

      # Push messages to a user using user_id.
      #
      # @param user_id [String] User Id
      # @param messages [Hash, Array] Message Objects
      # @param headers [Hash] HTTP Headers
      # @param payload [Hash] Additional request body
      # @return [Net::HTTPResponse]
      def push_message(user_id, messages, headers: {}, payload: {})
        channel_token_required

        messages = [messages] if messages.is_a?(Hash)

        endpoint_path = '/bot/message/push'
        payload = payload.merge({ to: user_id, messages: messages }).to_json
        post(endpoint, endpoint_path, payload, credentials.merge(headers))
      end

      # Reply messages to a user using replyToken.
      #
      # @example Send a balloon to a user.
      #   message = {
      #     type: 'text',
      #     text: 'Hello, World!'
      #   }
      #   client.reply_message(event['replyToken'], message)
      #
      # @example Send multiple balloons to a user.
      #
      #   messages = [
      #    {type: 'text', text: 'Message1'},
      #    {type: 'text', text: 'Message2'}
      #   ]
      #   client.reply_message(event['replyToken'], messages)
      #
      # @param token [String] Reply Token
      # @param messages [Hash, Array] Message Objects
      # @return [Net::HTTPResponse]
      def reply_message(token, messages)
        channel_token_required

        messages = [messages] if messages.is_a?(Hash)

        endpoint_path = '/bot/message/reply'
        payload = { replyToken: token, messages: messages }.to_json
        post(endpoint, endpoint_path, payload, credentials)
      end

      # Send messages to multiple users using userIds.
      #
      # @param to [Array, String] Array of userIds
      # @param messages [Hash, Array] Message Objects
      # @param headers [Hash] HTTP Headers
      # @param payload [Hash] Additional request body
      # @return [Net::HTTPResponse]
      def multicast(to, messages, headers: {}, payload: {})
        channel_token_required

        to = [to] if to.is_a?(String)
        messages = [messages] if messages.is_a?(Hash)

        endpoint_path = '/bot/message/multicast'
        payload = payload.merge({ to: to, messages: messages }).to_json
        post(endpoint, endpoint_path, payload, credentials.merge(headers))
      end

      # Send messages to all friends.
      #
      # @param messages [Hash, Array] Message Objects
      # @param headers [Hash] HTTP Headers
      #
      # @return [Net::HTTPResponse]
      def broadcast(messages, headers: {})
        channel_token_required

        messages = [messages] if messages.is_a?(Hash)

        endpoint_path = '/bot/message/broadcast'
        payload = { messages: messages }.to_json
        post(endpoint, endpoint_path, payload, credentials.merge(headers))
      end

      # Narrowcast messages to users
      #
      # API Documentation is here.
      # https://developers.line.biz/en/reference/messaging-api/#send-narrowcast-message
      #
      # @param messages [Hash, Array]
      # @param recipient [Hash]
      # @param filter [Hash]
      # @param limit [Hash]
      # @param headers [Hash] HTTP Headers
      #
      # @return [Net::HTTPResponse]
      def narrowcast(messages, recipient: nil, filter: nil, limit: nil, headers: {})
        channel_token_required

        messages = [messages] if messages.is_a?(Hash)

        endpoint_path = '/bot/message/narrowcast'
        payload = {
          messages: messages,
          recipient: recipient,
          filter: filter,
          limit: limit
        }.to_json
        post(endpoint, endpoint_path, payload, credentials.merge(headers))
      end

      def leave_group(group_id)
        channel_token_required

        endpoint_path = "/bot/group/#{group_id}/leave"
        post(endpoint, endpoint_path, nil, credentials)
      end

      def leave_room(room_id)
        channel_token_required

        endpoint_path = "/bot/room/#{room_id}/leave"
        post(endpoint, endpoint_path, nil, credentials)
      end

      # Get message content.
      #
      # @param identifier [String] Message's identifier
      # @return [Net::HTTPResponse]
      def get_message_content(identifier)
        channel_token_required

        endpoint_path = "/bot/message/#{identifier}/content"
        get(blob_endpoint, endpoint_path, credentials)
      end

      # Get an user's profile.
      #
      # @param user_id [String] User Id user_id
      # @return [Net::HTTPResponse]
      def get_profile(user_id)
        channel_token_required

        endpoint_path = "/bot/profile/#{user_id}"
        get(endpoint, endpoint_path, credentials)
      end

      # Get an user's profile of a group.
      #
      # @param group_id [String] Group's identifier
      # @param user_id [String] User Id user_id
      #
      # @return [Net::HTTPResponse]
      def get_group_member_profile(group_id, user_id)
        channel_token_required

        endpoint_path = "/bot/group/#{group_id}/member/#{user_id}"
        get(endpoint, endpoint_path, credentials)
      end

      # Get an user's profile of a room.
      #
      # @param room_id [String] Room's identifier
      # @param user_id [String] User Id user_id
      #
      # @return [Net::HTTPResponse]
      def get_room_member_profile(room_id, user_id)
        channel_token_required

        endpoint_path = "/bot/room/#{room_id}/member/#{user_id}"
        get(endpoint, endpoint_path, credentials)
      end

      # Get user IDs of who added your LINE Official Account as a friend
      #
      # @param start [String] Identifier to return next page (next property to be included in the response)
      # @param limit [Integer] The maximum number of user IDs to retrieve in a single request
      #
      # @return [Net::HTTPResponse]
      def get_follower_ids(deprecated_continuation_token = nil, start: nil, limit: nil)
        channel_token_required

        if deprecated_continuation_token
          warn "continuation_token as the first argument is deprecated. Please use :start instead."
          start = deprecated_continuation_token
        end

        params = { start: start, limit: limit }.compact

        endpoint_path = "/bot/followers/ids"
        endpoint_path += "?" + URI.encode_www_form(params) unless params.empty?
        get(endpoint, endpoint_path, credentials)
      end

      # Get user IDs of a group
      #
      # @param group_id [String] Group's identifier
      # @param continuation_token [String] Identifier to return next page
      #                                   (next property to be included in the response)
      #
      # @return [Net::HTTPResponse]
      def get_group_member_ids(group_id, continuation_token = nil)
        channel_token_required

        endpoint_path = "/bot/group/#{group_id}/members/ids"
        endpoint_path += "?start=#{continuation_token}" if continuation_token
        get(endpoint, endpoint_path, credentials)
      end

      # Get user IDs of a room
      #
      # @param room_id [String] Room's identifier
      # @param continuation_token [String] Identifier to return next page
      #                                   (next property to be included in the response)
      #
      # @return [Net::HTTPResponse]
      def get_room_member_ids(room_id, continuation_token = nil)
        channel_token_required

        endpoint_path = "/bot/room/#{room_id}/members/ids"
        endpoint_path += "?start=#{continuation_token}" if continuation_token
        get(endpoint, endpoint_path, credentials)
      end

      # Gets the group ID, group name, and group icon URL of a group where the LINE Official Account is a member.
      #
      # @param group_id [String] Group's identifier
      #
      # @return [Net::HTTPResponse]
      def get_group_summary(group_id)
        channel_token_required

        endpoint_path = "/bot/group/#{group_id}/summary"
        get(endpoint, endpoint_path, credentials)
      end

      # Gets the user IDs of the members of a group that the bot is in.
      #
      # @param group_id [String] Group's identifier
      #
      # @return [Net::HTTPResponse]
      def get_group_members_count(group_id)
        channel_token_required

        endpoint_path = "/bot/group/#{group_id}/members/count"
        get(endpoint, endpoint_path, credentials)
      end

      # Gets the count of members in a room.
      #
      # @param room_id [String] Room's identifier
      #
      # @return [Net::HTTPResponse]
      def get_room_members_count(room_id)
        channel_token_required

        endpoint_path = "/bot/room/#{room_id}/members/count"
        get(endpoint, endpoint_path, credentials)
      end

      # Get a list of all uploaded rich menus
      #
      # @return [Net::HTTPResponse]
      def get_rich_menus
        channel_token_required

        endpoint_path = '/bot/richmenu/list'
        get(endpoint, endpoint_path, credentials)
      end

      # Get a rich menu via a rich menu ID
      #
      # @param rich_menu_id [String] ID of an uploaded rich menu
      #
      # @return [Net::HTTPResponse]
      def get_rich_menu(rich_menu_id)
        channel_token_required

        endpoint_path = "/bot/richmenu/#{rich_menu_id}"
        get(endpoint, endpoint_path, credentials)
      end

      # Gets the number of messages sent with the /bot/message/reply endpoint.
      #
      # @param date [String] Date the messages were sent (format: yyyyMMdd)
      #
      # @return [Net::HTTPResponse]
      def get_message_delivery_reply(date)
        channel_token_required

        endpoint_path = "/bot/message/delivery/reply?date=#{date}"
        get(endpoint, endpoint_path, credentials)
      end

      # Gets the number of messages sent with the /bot/message/push endpoint.
      #
      # @param date [String] Date the messages were sent (format: yyyyMMdd)
      #
      # @return [Net::HTTPResponse]
      def get_message_delivery_push(date)
        channel_token_required

        endpoint_path = "/bot/message/delivery/push?date=#{date}"
        get(endpoint, endpoint_path, credentials)
      end

      # Gets the number of messages sent with the /bot/message/multicast endpoint.
      #
      # @param date [String] Date the messages were sent (format: yyyyMMdd)
      #
      # @return [Net::HTTPResponse]
      def get_message_delivery_multicast(date)
        channel_token_required

        endpoint_path = "/bot/message/delivery/multicast?date=#{date}"
        get(endpoint, endpoint_path, credentials)
      end

      # Gets the number of messages sent with the /bot/message/multicast endpoint.
      #
      # @param date [String] Date the messages were sent (format: yyyyMMdd)
      #
      # @return [Net::HTTPResponse]
      def get_message_delivery_broadcast(date)
        channel_token_required

        endpoint_path = "/bot/message/delivery/broadcast?date=#{date}"
        get(endpoint, endpoint_path, credentials)
      end

      # Validate message objects of a reply message
      #
      # @param messages [Array] Array of message objects to validate
      #
      # @return [Net::HTTPResponse]
      def validate_reply_message_objects(messages)
        channel_token_required

        endpoint_path = '/bot/message/validate/reply'
        payload = { messages: messages }.to_json
        post(endpoint, endpoint_path, payload, credentials)
      end

      # Validate message objects of a push message
      #
      # @param messages [Array] Array of message objects to validate
      #
      # @return [Net::HTTPResponse]
      def validate_push_message_objects(messages)
        channel_token_required

        endpoint_path = '/bot/message/validate/push'
        payload = { messages: messages }.to_json
        post(endpoint, endpoint_path, payload, credentials)
      end

      # Validate message objects of a multicast message
      #
      # @param messages [Array] Array of message objects to validate
      #
      # @return [Net::HTTPResponse]
      def validate_multicast_message_objects(messages)
        channel_token_required

        endpoint_path = '/bot/message/validate/multicast'
        payload = { messages: messages }.to_json
        post(endpoint, endpoint_path, payload, credentials)
      end

      # Validate message objects of a narrowcast message
      #
      # @param messages [Array] Array of message objects to validate
      #
      # @return [Net::HTTPResponse]
      def validate_narrowcast_message_objects(messages)
        channel_token_required

        endpoint_path = '/bot/message/validate/narrowcast'
        payload = { messages: messages }.to_json
        post(endpoint, endpoint_path, payload, credentials)
      end

      # Validate message objects of a broadcast message
      #
      # @param messages [Array] Array of message objects to validate
      #
      # @return [Net::HTTPResponse]
      def validate_broadcast_message_objects(messages)
        channel_token_required

        endpoint_path = '/bot/message/validate/broadcast'
        payload = { messages: messages }.to_json
        post(endpoint, endpoint_path, payload, credentials)
      end

      # Create a rich menu
      #
      # @param rich_menu [Hash] The rich menu represented as a rich menu object
      #
      # @return [Net::HTTPResponse]
      def create_rich_menu(rich_menu)
        channel_token_required

        endpoint_path = '/bot/richmenu'
        post(endpoint, endpoint_path, rich_menu.to_json, credentials)
      end

      # Validate a rich menu object
      #
      # @param rich_menu [Hash] The rich menu represented as a rich menu object
      #
      # @return [Net::HTTPResponse]
      def validate_rich_menu_object(rich_menu)
        channel_token_required

        endpoint_path = '/bot/richmenu/validate'
        post(endpoint, endpoint_path, rich_menu.to_json, credentials)
      end

      # Delete a rich menu
      #
      # @param rich_menu_id [String] ID of an uploaded rich menu
      #
      # @return [Net::HTTPResponse]
      def delete_rich_menu(rich_menu_id)
        channel_token_required

        endpoint_path = "/bot/richmenu/#{rich_menu_id}"
        delete(endpoint, endpoint_path, credentials)
      end

      # Get the ID of the rich menu linked to a user
      #
      # @param user_id [String] ID of the user
      #
      # @return [Net::HTTPResponse]
      def get_user_rich_menu(user_id)
        channel_token_required

        endpoint_path = "/bot/user/#{user_id}/richmenu"
        get(endpoint, endpoint_path, credentials)
      end

      # Get default rich menu
      #
      # @return [Net::HTTPResponse]
      def get_default_rich_menu
        channel_token_required

        endpoint_path = '/bot/user/all/richmenu'
        get(endpoint, endpoint_path, credentials)
      end

      # Set default rich menu (Link a rich menu to all user)
      #
      # @param rich_menu_id [String] ID of an uploaded rich menu
      #
      # @return [Net::HTTPResponse]
      def set_default_rich_menu(rich_menu_id)
        channel_token_required

        endpoint_path = "/bot/user/all/richmenu/#{rich_menu_id}"
        post(endpoint, endpoint_path, nil, credentials)
      end

      # Unset default rich menu (Unlink a rich menu from all user)
      #
      # @return [Net::HTTPResponse]
      def unset_default_rich_menu
        channel_token_required

        endpoint_path = "/bot/user/all/richmenu"
        delete(endpoint, endpoint_path, credentials)
      end

      # Set rich menu alias
      #
      # @param rich_menu_id [String] ID of an uploaded rich menu
      # @param rich_menu_alias_id [String] string of alias words rich menu
      #
      # @return [Net::HTTPResponse]
      def set_rich_menus_alias(rich_menu_id, rich_menu_alias_id)
        channel_token_required

        endpoint_path = '/bot/richmenu/alias'
        post(endpoint, endpoint_path, { richMenuId: rich_menu_id, richMenuAliasId: rich_menu_alias_id }.to_json, credentials)
      end

      # Unset rich menu alias
      #
      # @param rich_menu_alias_id [String] string of alias words rich menu
      #
      # @return [Net::HTTPResponse]
      def unset_rich_menus_alias(rich_menu_alias_id)
        channel_token_required

        endpoint_path = "/bot/richmenu/alias/#{rich_menu_alias_id}"
        delete(endpoint, endpoint_path, credentials)
      end

      # Update rich menu alias
      #
      # @param rich_menu_id [String] ID of an uploaded rich menu
      # @param rich_menu_alias_id [String] string of alias words rich menu
      #
      # @return [Net::HTTPResponse]
      def update_rich_menus_alias(rich_menu_id, rich_menu_alias_id)
        channel_token_required

        endpoint_path = "/bot/richmenu/alias/#{rich_menu_alias_id}"
        post(endpoint, endpoint_path, { richMenuId: rich_menu_id }.to_json, credentials)
      end

      # Get a rich menu alias via a rich menu alias ID
      #
      # @param rich_menu_alias_id [String] string of alias words rich menu
      #
      # @return [Net::HTTPResponse]
      def get_rich_menus_alias(rich_menu_alias_id)
        channel_token_required

        endpoint_path = "/bot/richmenu/alias/#{rich_menu_alias_id}"
        get(endpoint, endpoint_path, credentials)
      end

      # Get a list of all uploaded rich menus alias
      #
      # @return [Net::HTTPResponse]
      def get_rich_menus_alias_list
        channel_token_required

        endpoint_path = "/bot/richmenu/alias/list"
        get(endpoint, endpoint_path, credentials)
      end

      # Link a rich menu to a user
      #
      # If you want to link a rich menu to multiple users,
      # please consider to use bulk_link_rich_menus.
      #
      # @param user_id [String] ID of the user
      # @param rich_menu_id [String] ID of an uploaded rich menu
      #
      # @return [Net::HTTPResponse]
      def link_user_rich_menu(user_id, rich_menu_id)
        channel_token_required

        endpoint_path = "/bot/user/#{user_id}/richmenu/#{rich_menu_id}"
        post(endpoint, endpoint_path, nil, credentials)
      end

      # Unlink a rich menu from a user
      #
      # @param user_id [String] ID of the user
      #
      # @return [Net::HTTPResponse]
      def unlink_user_rich_menu(user_id)
        channel_token_required

        endpoint_path = "/bot/user/#{user_id}/richmenu"
        delete(endpoint, endpoint_path, credentials)
      end

      # To link a rich menu to multiple users at a time
      #
      # @param user_ids [Array] ID of the user
      # @param rich_menu_id [String] ID of the uploaded rich menu
      #
      # @return [Net::HTTPResponse]
      def bulk_link_rich_menus(user_ids, rich_menu_id)
        channel_token_required

        endpoint_path = "/bot/richmenu/bulk/link"
        post(endpoint, endpoint_path, { richMenuId: rich_menu_id, userIds: user_ids }.to_json, credentials)
      end

      # To unlink a rich menu from multiple users at a time
      #
      # @param user_ids [Array] ID of the user
      #
      # @return [Net::HTTPResponse]
      def bulk_unlink_rich_menus(user_ids)
        channel_token_required

        endpoint_path = "/bot/richmenu/bulk/unlink"
        post(endpoint, endpoint_path, { userIds: user_ids }.to_json, credentials)
      end

      # Download an image associated with a rich menu
      #
      # @param rich_menu_id [String] ID of an uploaded rich menu
      #
      # @return [Net::HTTPResponse]
      def get_rich_menu_image(rich_menu_id)
        channel_token_required

        endpoint_path = "/bot/richmenu/#{rich_menu_id}/content"
        get(blob_endpoint, endpoint_path, credentials)
      end

      # Upload and attaches an image to a rich menu
      #
      # @param rich_menu_id [String] The ID of the rich menu to attach the image to
      # @param file [File] Image file to attach rich menu
      #
      # @return [Net::HTTPResponse]
      def create_rich_menu_image(rich_menu_id, file)
        channel_token_required

        endpoint_path = "/bot/richmenu/#{rich_menu_id}/content"
        headers = credentials.merge('Content-Type' => content_type(file))
        post(blob_endpoint, endpoint_path, file.rewind && file.read, headers)
      end

      # Issue a link token to a user
      #
      # @param user_id [String] ID of the user
      #
      # @return [Net::HTTPResponse]
      def create_link_token(user_id)
        channel_token_required

        endpoint_path = "/bot/user/#{user_id}/linkToken"
        post(endpoint, endpoint_path, nil, credentials)
      end

      # Get the target limit for additional messages
      #
      # @return [Net::HTTPResponse]
      def get_quota
        channel_token_required

        endpoint_path = "/bot/message/quota"
        get(endpoint, endpoint_path, credentials)
      end

      # Get number of messages sent this month
      #
      # @return [Net::HTTPResponse]
      def get_quota_consumption
        channel_token_required

        endpoint_path = "/bot/message/quota/consumption"
        get(endpoint, endpoint_path, credentials)
      end

      # Returns the number of messages sent on a specified day
      #
      # @param [String] date (Format:yyyyMMdd, Example:20191231)
      #
      # @return [Net::HTTPResponse]
      def get_number_of_message_deliveries(date)
        channel_token_required

        endpoint_path = "/bot/insight/message/delivery?date=#{date}"
        get(endpoint, endpoint_path, credentials)
      end

      # Returns statistics about how users interact with narrowcast messages or broadcast messages sent from your LINE Official Account.
      #
      # @param [String] request_id
      #
      # @return [Net::HTTPResponse]
      def get_user_interaction_statistics(request_id)
        channel_token_required

        endpoint_path = "/bot/insight/message/event?requestId=#{request_id}"
        get(endpoint, endpoint_path, credentials)
      end

      # Returns the number of followers
      #
      # @param [String] date (Format:yyyyMMdd, Example:20191231)
      #
      # @return [Net::HTTPResponse]
      def get_number_of_followers(date)
        channel_token_required

        endpoint_path = "/bot/insight/followers?date=#{date}"
        get(endpoint, endpoint_path, credentials)
      end

      # Get the demographic attributes for a bot's friends.
      #
      # @return [Net::HTTPResponse]
      def get_friend_demographics
        channel_token_required

        endpoint_path = '/bot/insight/demographic'
        get(endpoint, endpoint_path, credentials)
      end

      # Gets a bot's basic information.
      #
      # @return [Net::HTTPResponse]
      def get_bot_info
        channel_token_required

        endpoint_path = '/bot/info'
        get(endpoint, endpoint_path, credentials)
      end

      # Gets information on a webhook endpoint.
      #
      # @return [Net::HTTPResponse]
      def get_webhook_endpoint
        channel_token_required

        endpoint_path = '/bot/channel/webhook/endpoint'
        get(endpoint, endpoint_path, credentials)
      end

      # Sets the webhook endpoint URL.
      #
      # @param webhook_endpoint [String]
      #
      # @return [Net::HTTPResponse]
      def set_webhook_endpoint(webhook_endpoint)
        channel_token_required

        endpoint_path = '/bot/channel/webhook/endpoint'
        body = {endpoint: webhook_endpoint}
        put(endpoint, endpoint_path, body.to_json, credentials)
      end

      # Checks if the configured webhook endpoint can receive a test webhook event.
      #
      # @param webhook_endpoint [String] options
      #
      # @return [Net::HTTPResponse]
      def test_webhook_endpoint(webhook_endpoint = nil)
        channel_token_required

        endpoint_path = '/bot/channel/webhook/test'
        body = if webhook_endpoint.nil?
                 {}
               else
                 {endpoint: webhook_endpoint}
               end
        post(endpoint, endpoint_path, body.to_json, credentials)
      end

      def get_liff_apps
        channel_token_required

        endpoint_path = '/apps'
        get(liff_endpoint, endpoint_path, credentials)
      end

      def create_liff_app(app)
        channel_token_required

        endpoint_path = '/apps'
        post(liff_endpoint, endpoint_path, app.to_json, credentials)
      end

      def update_liff_app(liff_id, app)
        channel_token_required

        endpoint_path = "/apps/#{liff_id}"
        put(liff_endpoint, endpoint_path, app.to_json, credentials)
      end

      def delete_liff_app(liff_id)
        channel_token_required

        endpoint_path = "/apps/#{liff_id}"
        delete(liff_endpoint, endpoint_path, credentials)
      end

      # Create an audience group by uploading user_ids
      #
      # Parameters are described here.
      # https://developers.line.biz/en/reference/messaging-api/#create-upload-audience-group
      #
      # @param params [Hash] options
      #
      # @return [Net::HTTPResponse] This response includes an audience_group_id.
      def create_user_id_audience(params)
        channel_token_required

        endpoint_path = '/bot/audienceGroup/upload'
        post(endpoint, endpoint_path, params.to_json, credentials)
      end

      # Update an audience group
      #
      # Parameters are described here.
      # https://developers.line.biz/en/reference/messaging-api/#update-upload-audience-group
      #
      # @param params [Hash] options
      #
      # @return [Net::HTTPResponse] This response includes an audience_group_id.
      def update_user_id_audience(params)
        channel_token_required

        endpoint_path = '/bot/audienceGroup/upload'
        put(endpoint, endpoint_path, params.to_json, credentials)
      end

      # Create an audience group of users that clicked a URL in a message sent in the past
      #
      # Parameters are described here.
      # https://developers.line.biz/en/reference/messaging-api/#create-click-audience-group
      #
      # @param params [Hash] options
      #
      # @return [Net::HTTPResponse] This response includes an audience_group_id.
      def create_click_audience(params)
        channel_token_required

        endpoint_path = '/bot/audienceGroup/click'
        post(endpoint, endpoint_path, params.to_json, credentials)
      end

      # Create an audience group of users that opened a message sent in the past
      #
      # Parameters are described here.
      # https://developers.line.biz/en/reference/messaging-api/#create-imp-audience-group
      #
      # @param params [Hash] options
      #
      # @return [Net::HTTPResponse] This response includes an audience_group_id.
      def create_impression_audience(params)
        channel_token_required

        endpoint_path = '/bot/audienceGroup/imp'
        post(endpoint, endpoint_path, params.to_json, credentials)
      end

      # Rename an existing audience group
      #
      # @param audience_group_id [Integer]
      # @param description [String]
      #
      # @return [Net::HTTPResponse]
      def rename_audience(audience_group_id, description)
        channel_token_required

        endpoint_path = "/bot/audienceGroup/#{audience_group_id}/updateDescription"
        body = {description: description}
        put(endpoint, endpoint_path, body.to_json, credentials)
      end

      # Delete an existing audience group
      #
      # Parameters are described here.
      # https://developers.line.biz/en/reference/messaging-api/#delete-audience-group
      #
      # @param audience_group_id [Integer]
      #
      # @return [Net::HTTPResponse]
      def delete_audience(audience_group_id)
        channel_token_required

        endpoint_path = "/bot/audienceGroup/#{audience_group_id}"
        delete(endpoint, endpoint_path, credentials)
      end

      # Get audience group data
      #
      # Parameters are described here.
      # https://developers.line.biz/en/reference/messaging-api/#get-audience-group
      #
      # @param audience_group_id [Integer]
      #
      # @return [Net::HTTPResponse]
      def get_audience(audience_group_id)
        channel_token_required

        endpoint_path = "/bot/audienceGroup/#{audience_group_id}"
        get(endpoint, endpoint_path, credentials)
      end

      # Get data for more than one audience group
      #
      # Parameters are described here.
      # https://developers.line.biz/en/reference/messaging-api/#get-audience-groups
      #
      # @param params [Hash] key name `page` is required
      #
      # @return [Net::HTTPResponse]
      def get_audiences(params)
        channel_token_required

        endpoint_path = "/bot/audienceGroup/list?" + URI.encode_www_form(params)
        get(endpoint, endpoint_path, credentials)
      end

      # Get the authority level of the audience
      #
      # Parameters are described here.
      # https://developers.line.biz/en/reference/messaging-api/#get-authority-level
      #
      # @return [Net::HTTPResponse]
      def get_audience_authority_level
        channel_token_required

        endpoint_path = "/bot/audienceGroup/authorityLevel"
        get(endpoint, endpoint_path, credentials)
      end

      # Change the authority level of the audience
      #
      # Parameters are described here.
      # https://developers.line.biz/en/reference/messaging-api/#change-authority-level
      #
      # @param authority_level [String] value must be `PUBLIC` or `PRIVATE`
      #
      # @return [Net::HTTPResponse]
      def update_audience_authority_level(authority_level)
        channel_token_required

        endpoint_path = "/bot/audienceGroup/authorityLevel"
        body = {authorityLevel: authority_level}
        put(endpoint, endpoint_path, body.to_json, credentials)
      end

      # Get the per-unit statistics of how users interact with push messages and multicast messages.
      #
      # @param unit [String] Case-sensitive name of aggregation unit specified when sending the message.
      # @param from [String] Start date of aggregation period in UTC+9 with `yyyyMMdd` format
      # @param to [String] End date of aggregation period in UTC+9 with `yyyyMMdd` format.
      #
      # @return [Net::HTTPResponse]
      def get_statistics_per_unit(unit:, from:, to:)
        channel_token_required

        params = {customAggregationUnit: unit, from: from, to: to}
        endpoint_path = "/bot/insight/message/event/aggregation?" + URI.encode_www_form(params)
        get(endpoint, endpoint_path, credentials)
      end

      # Get the number of aggregation units used this month.
      #
      # @return [Net::HTTPResponse]
      def get_aggregation_info
        channel_token_required

        endpoint_path = "/bot/message/aggregation/info"
        get(endpoint, endpoint_path, credentials)
      end

      # Get the name list of units used this month for statistics aggregation.
      #
      # @param limit [Integer] Maximum number of aggregation units per request. Maximum: 100, Default: 100.
      # @param start [String] Value of the continuation token found in the `next` property of the JSON object returned in the response.
      #
      # @return [Net::HTTPResponse]
      def get_aggregation_list(limit: nil, start: nil)
        channel_token_required

        params = {limit: limit, start: start}.compact
        endpoint_path = "/bot/message/aggregation/list?" + URI.encode_www_form(params)
        get(endpoint, endpoint_path, credentials)
      end

      # Gets the status of a narrowcast message.
      #
      # @param request_id [String] The narrowcast message's request ID. Each Messaging API request has a request ID. Find it in the response headers.
      #
      # @return [Net::HTTPResponse]
      def get_narrowcast_message_status(request_id)
        channel_token_required

        endpoint_path = "/bot/message/progress/narrowcast?requestId=#{request_id}"
        get(endpoint, endpoint_path, credentials)
      end

      # Send messages to multiple users using phone numbers.
      #
      # @param to [Array, String] Array of hashed phone numbers.
      # @param messages [Hash, Array] Message Objects.
      # @param headers [Hash] HTTP Headers.
      # @param payload [Hash] Additional request body.
      #
      # @return [Net::HTTPResponse]

      def multicast_by_phone_numbers(to, messages, headers: {}, payload: {})
        channel_token_required

        to = [to] if to.is_a?(String)
        messages = [messages] if messages.is_a?(Hash)

        endpoint_path = 'bot/ad/multicast/phone'
        payload = payload.merge({ to: to, messages: messages }).to_json
        post(oauth_endpoint, endpoint_path, payload, credentials.merge(headers))
      end

      # Get the delivery result of the message delivered in Send message using phone number. (`#multicast_by_phone_numbers`)
      #
      # @param date [String] Date the message was sent in UTC+9 with `yyyyMMdd` format.
      #
      # @return [Net::HTTPResponse]

      def get_delivery_result_sent_by_phone_numbers(date)
        channel_token_required

        endpoint_path = "/bot/message/delivery/ad_phone?date=#{date}"
        get(endpoint, endpoint_path, credentials)
      end

      # Fetch data, get content of specified URL.
      #
      # @param endpoint_base [String]
      # @param endpoint_path [String]
      # @param headers [Hash]
      #
      # @return [Net::HTTPResponse]
      def get(endpoint_base, endpoint_path, headers = {})
        headers = API::DEFAULT_HEADERS.merge(headers)
        httpclient.get(endpoint_base + endpoint_path, headers)
      end

      # Post data, get content of specified URL.
      #
      # @param endpoint_base [String]
      # @param endpoint_path [String]
      # @param payload [String, NilClass]
      # @param headers [Hash]
      #
      # @return [Net::HTTPResponse]
      def post(endpoint_base, endpoint_path, payload = nil, headers = {})
        headers = API::DEFAULT_HEADERS.merge(headers)
        httpclient.post(endpoint_base + endpoint_path, payload, headers)
      end

      # Put data, get content of specified URL.
      #
      # @param endpoint_base [String]
      # @param endpoint_path [String]
      # @param payload [String, NilClass]
      # @param headers [Hash]
      #
      # @return [Net::HTTPResponse]
      def put(endpoint_base, endpoint_path, payload = nil, headers = {})
        headers = API::DEFAULT_HEADERS.merge(headers)
        httpclient.put(endpoint_base + endpoint_path, payload, headers)
      end

      # Delete content of specified URL.
      #
      # @param endpoint_base [String]
      # @param endpoint_path [String]
      # @param headers [Hash]
      #
      # @return [Net::HTTPResponse]
      def delete(endpoint_base, endpoint_path, headers = {})
        headers = API::DEFAULT_HEADERS.merge(headers)
        httpclient.delete(endpoint_base + endpoint_path, headers)
      end

      # Parse events from request.body
      #
      # @param request_body [String]
      #
      # @return [Array<Line::Bot::Event::Class>]
      def parse_events_from(request_body)
        json = JSON.parse(request_body)

        json['events'].map do |item|
          begin
            klass = Event.const_get(Util.camelize(item['type']))
            klass.new(item)
          rescue NameError
            Event::Base.new(item)
          end
        end
      end

      # Validate signature of a webhook event.
      #
      # https://developers.line.biz/en/reference/messaging-api/#signature-validation
      #
      # @param content [String] Request's body
      # @param channel_signature [String] Request'header 'X-LINE-Signature' # HTTP_X_LINE_SIGNATURE
      #
      # @return [Boolean]
      def validate_signature(content, channel_signature)
        return false if !channel_signature || !channel_secret

        hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), channel_secret, content)
        signature = Base64.strict_encode64(hash)

        variable_secure_compare(channel_signature, signature)
      end

      private

      # Constant time string comparison.
      #
      # via timing attacks.
      # reference: https://github.com/rails/rails/blob/master/activesupport/lib/active_support/security_utils.rb
      # @return [Boolean]
      def variable_secure_compare(a, b)
        secure_compare(::Digest::SHA256.hexdigest(a), ::Digest::SHA256.hexdigest(b))
      end

      # @return [Boolean]
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack "C#{a.bytesize}"

        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res == 0
      end

      def content_type(file)
        if file.respond_to?(:content_type)
          content_type = file.content_type
          raise ArgumentError, "invalid content type: #{content_type}" unless ['image/jpeg', 'image/png'].include?(content_type)

          content_type
        else
          case file.path
          when /\.jpe?g\z/i then 'image/jpeg'
          when /\.png\z/i   then 'image/png'
          else
            raise ArgumentError, "invalid file extension: #{file.path}"
          end
        end
      end

      def channel_token_required
        raise ArgumentError, '`channel_token` is not configured' unless channel_token
      end

      def channel_id_required
        raise ArgumentError, '`channel_id` is not configured' unless channel_id
      end

      def channel_secret_required
        raise ArgumentError, '`channel_secret` is not configured' unless channel_secret
      end
    end
  end
end

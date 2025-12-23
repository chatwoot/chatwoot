# frozen_string_literal: true
require_relative 'ids.id'

module Slack
  module Web
    module Api
      module Mixins
        module Conversations
          include Ids
          #
          # This method returns a channel ID given a channel name.
          #
          # @option options [channel] :channel
          #   Channel to get ID for, prefixed with #.
          # @option options [string] :team_id
          #   The team id to search for channels in, required if token belongs to org-wide app.
          #   This field will be ignored if the API call is sent using a workspace-level token.
          # @option options [boolean] :id_exclude_archived
          #   Set to true to exclude archived channels from the search
          # @option options [integer] :id_limit
          #   The page size used for conversations_list calls required to find the channel's ID
          # @option options [string] :id_types
          #   The types of conversations to use when searching for the ID. A comma-separated list
          #   containing one or more of public_channel, private_channel, mpim, im
          def conversations_id(options = {})
            name = options[:channel]
            raise ArgumentError, 'Required arguments :channel missing' if name.nil?

            id_for(
              key: :channel,
              name: name,
              prefix: '#',
              enum_method: :conversations_list,
              list_method: :channels,
              options: {
                team_id: options.fetch(:team_id, nil),
                exclude_archived: options.fetch(:id_exclude_archived, nil),
                limit: options.fetch(:id_limit, Slack::Web.config.conversations_id_page_size),
                types: options.fetch(:id_types, nil)
              }.compact
            )
          end
        end
      end
    end
  end
end

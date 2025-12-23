# frozen_string_literal: true
require_relative 'ids.id'

module Slack
  module Web
    module Api
      module Mixins
        module Users
          include Ids
          #
          # This method returns a user ID given a user name.
          #
          # @option options [user] :user
          #   User to get ID for, prefixed with '@'.
          # @option options [string] :team_id
          #   The team id to search for users in, required if token belongs to org-wide app.
          #   This field will be ignored if the API call is sent using a workspace-level token.
          # @option options [integer] :id_limit
          #   The page size used for users_list calls required to find the user's ID
          def users_id(options = {})
            name = options[:user]
            raise ArgumentError, 'Required arguments :user missing' if name.nil?

            id_for(
              key: :user,
              name: name,
              prefix: '@',
              enum_method: :users_list,
              list_method: :members,
              options: {
                team_id: options.fetch(:team_id, nil),
                limit: options.fetch(:id_limit, Slack::Web.config.users_id_page_size)
              }.compact
            )
          end
        end
      end
    end
  end
end

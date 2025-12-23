# frozen_string_literal: true

module Slack
  module RealTime
    module Stores
      # Full store with initialization logic
      class Store < Base
        CONVERSATION_TYPES = {
          public_channels: 'public_channel',
          private_channels: 'private_channel',
          ims: 'im',
          mpims: 'mpim'
        }.freeze

        attr_reader :caches

        def initialize(attrs, options = {})
          @teams = {}
          @users = {}
          @bots = {}
          @public_channels = {}
          @private_channels = {}
          @ims = {}
          @mpims = {}

          if attrs.team
            @team_id = attrs.team.id
            @teams[@team_id] = Models::Team.new(attrs.team)
          end

          if attrs.self
            @self_id = attrs.self.id
            @users[@self_id] = Models::User.new(attrs.self)
          end

          @caches =
            if options[:caches].is_a?(Array) || options[:caches].nil?
              caches = options[:caches].to_a.map(&:to_sym)
              unknown_caches = caches - CACHES
              raise ArgumentError, "Unknown caches: #{unknown_caches.join(', ')}" unless unknown_caches.empty?

              Set.new(caches).freeze
            elsif options[:caches] == :all
              Set.new(CACHES).freeze
            else
              raise ArgumentError, 'Unexpected value for option `caches`. Expects :all or an array of caches'
            end
        end

        def self
          users[@self_id]
        end

        def team
          teams[@team_id]
        end

        ### RealTime Events

        # The list of accounts a user is signed into has changed.
        # @see https://api.slack.com/events/accounts_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/accounts_changed.json
        # on :accounts_changed do |data|

        # A bot user was added.
        # @see https://api.slack.com/events/bot_added
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/bot_added.json
        on :bot_added do |data|
          bot = Models::Bot.new(data.bot)
          bots[bot.id] = bot
        end

        # A bot user was changed.
        # @see https://api.slack.com/events/bot_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/bot_changed.json
        on :bot_changed do |data|
          bot = bots[data.bot.id]
          bot&.merge!(data.bot)
        end

        # A channel was archived.
        # @see https://api.slack.com/events/channel_archive
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/channel_archive.json
        on :channel_archive do |data|
          channel = public_channels[data.channel]
          channel.is_archived = true if channel
        end

        # A channel was created.
        # @see https://api.slack.com/events/channel_created
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/channel_created.json
        on :channel_created do |data|
          channel = Models::Channel.new(data.channel)
          public_channels[channel.id] = channel
        end

        # A channel was deleted.
        # @see https://api.slack.com/events/channel_deleted
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/channel_deleted.json
        on :channel_deleted do |data|
          public_channels.delete(data.channel)
        end

        # Bulk updates were made to a channel's history.
        # @see https://api.slack.com/events/channel_history_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/channel_history_changed.json
        # on :channel_history_changed do |data|

        # You joined a channel.
        # @see https://api.slack.com/events/channel_joined
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/channel_joined.json
        on :channel_joined do |data|
          channel_id = data.channel.id
          if data.channel.is_private?
            channel = private_channels[channel_id]
            if channel
              channel.merge!(data.channel)
            else
              private_channels[channel_id] = Models::Channel.new(data.channel)
            end
          else
            channel = public_channels[channel_id]
            if channel
              channel.merge!(data.channel)
            else
              public_channels[channel_id] = Models::Channel.new(data.channel)
            end
          end
        end

        # You left a channel.
        # @see https://api.slack.com/events/channel_left
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/channel_left.json
        on :channel_left do |data|
          channel = public_channels[data.channel]
          channel&.members&.delete(self.self.id)
        end

        # Your channel read marker was updated.
        # @see https://api.slack.com/events/channel_marked
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/channel_marked.json
        # on :channel_marked do |data|

        # A channel was renamed.
        # @see https://api.slack.com/events/channel_rename
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/channel_rename.json
        on :channel_rename do |data|
          channel = public_channels[data.channel.id]
          channel&.merge!(data.channel)
        end

        # A channel was unarchived.
        # @see https://api.slack.com/events/channel_unarchive
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/channel_unarchive.json
        on :channel_unarchive do |data|
          channel = public_channels[data.channel]
          channel.is_archived = false if channel
        end

        # A slash command has been added or changed.
        # @see https://api.slack.com/events/commands_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/commands_changed.json
        # on :commands_changed do |data|

        # Do not Disturb settings changed for the current user.
        # @see https://api.slack.com/events/dnd_updated
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/dnd_updated.json
        on :dnd_updated do |data|
          self.dnd_status = data.dnd_status
        end

        # Do not Disturb settings changed for a member.
        # @see https://api.slack.com/events/dnd_updated_user
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/dnd_updated_user.json
        on :dnd_updated_user do |data|
          user = users[data.user]
          user.dnd_status = data.dnd_status if user
        end

        # The workspace email domain has changed.
        # @see https://api.slack.com/events/email_domain_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/email_domain_changed.json
        on :email_domain_changed do |data|
          team.email_domain = data.email_domain
        end

        # A custom emoji has been added or changed.
        # @see https://api.slack.com/events/emoji_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/emoji_changed.json
        # on :emoji_changed do |data|

        # An enterprise grid migration has finished on an external workspace..
        # @see https://api.slack.com/events/external_org_migration_finished
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/external_org_migration_finished.json
        # on :external_org_migration_finished do |data|

        # An enterprise grid migration has started on an external workspace..
        # @see https://api.slack.com/events/external_org_migration_started
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/external_org_migration_started.json
        # on :external_org_migration_started do |data|

        # A file was changed.
        # @see https://api.slack.com/events/file_change
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/file_change.json
        # on :file_change do |data|

        # A file comment was added.
        # @see https://api.slack.com/events/file_comment_added
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/file_comment_added.json
        # on :file_comment_added do |data|

        # A file comment was deleted.
        # @see https://api.slack.com/events/file_comment_deleted
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/file_comment_deleted.json
        # on :file_comment_deleted do |data|

        # A file comment was edited.
        # @see https://api.slack.com/events/file_comment_edited
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/file_comment_edited.json
        # on :file_comment_edited do |data|

        # A file was created.
        # @see https://api.slack.com/events/file_created
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/file_created.json
        # on :file_created do |data|

        # A file was deleted.
        # @see https://api.slack.com/events/file_deleted
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/file_deleted.json
        # on :file_deleted do |data|

        # A file was made public.
        # @see https://api.slack.com/events/file_public
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/file_public.json
        # on :file_public do |data|

        # A file was shared.
        # @see https://api.slack.com/events/file_shared
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/file_shared.json
        # on :file_shared do |data|

        # A file was unshared.
        # @see https://api.slack.com/events/file_unshared
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/file_unshared.json
        # on :file_unshared do |data|

        # The server intends to close the connection soon..
        # @see https://api.slack.com/events/goodbye
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/goodbye.json
        # on :goodbye do |data|

        # A private channel was archived.
        # @see https://api.slack.com/events/group_archive
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_archive.json
        on :group_archive do |data|
          channel = private_channels[data.channel]
          channel.is_archived = true if channel
        end

        # You closed a private channel.
        # @see https://api.slack.com/events/group_close
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_close.json
        on :group_close do |data|
          channel = private_channels[data.channel]
          channel.is_open = false if channel
        end

        # A private channel was deleted.
        # @see https://api.slack.com/events/group_deleted
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_deleted.json
        on :group_deleted do |data|
          private_channels.delete(data.channel)
        end

        # Bulk updates were made to a private channel's history.
        # @see https://api.slack.com/events/group_history_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_history_changed.json
        # on :group_history_changed do |data|

        # You joined a private channel.
        # @see https://api.slack.com/events/group_joined
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_joined.json
        on :group_joined do |data|
          channel = Models::Channel.new(data.channel)
          private_channels[channel.id] = channel
        end

        # You left a private channel.
        # @see https://api.slack.com/events/group_left
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_left.json
        on :group_left do |data|
          # Deleting because we can't access a private channel when we're not a member
          private_channels.delete(data.channel)
        end

        # A private channel read marker was updated.
        # @see https://api.slack.com/events/group_marked
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_marked.json
        # on :group_marked do |data|

        # You created a group DM.
        # @see https://api.slack.com/events/group_open
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_open.json
        on :group_open do |data|
          channel = private_channels[data.channel]
          channel.is_open = true if channel
        end

        # A private channel was renamed.
        # @see https://api.slack.com/events/group_rename
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_rename.json
        on :group_rename do |data|
          channel = private_channels[data.channel.id]
          channel&.merge!(data.channel)
        end

        # A private channel was unarchived.
        # @see https://api.slack.com/events/group_unarchive
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/group_unarchive.json
        on :group_unarchive do |data|
          channel = private_channels[data.channel]
          channel.is_archived = false if channel
        end

        # The client has successfully connected to the server.
        # @see https://api.slack.com/events/hello
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/hello.json
        on :hello do |_data, client|
          # rubocop:disable Metrics/BlockNesting
          if caches.include?(:teams)
            team_info = client.web_client.team_info
            team = Models::Team.new(team_info.team)
            teams[team.id] = teams.key?(team.id) ? teams[team.id].merge(team) : team
          end

          if caches.include?(:users) || caches.include?(:bots)
            client.web_client.users_list do |users_list|
              users_list.members.each do |user_data|
                if caches.include?(:users)
                  user = Models::User.new(user_data)
                  users[user.id] = users.key?(user.id) ? users[user.id].merge(user) : user
                end

                next unless user_data.is_bot? && caches.include?(:bots)

                bot_info = client.web_client.bots_info(bot: user_data.profile.bot_id)
                bot = Models::Bot.new(bot_info.bot)
                bots[bot.id] = bots.key?(bot.id) ? bots[bot.id].merge(bot) : bot
              end
            end
          end

          if caches.include?(:public_channels) || caches.include?(:private_channels) ||
             caches.include?(:ims) || caches.include?(:mpims)
            types = CONVERSATION_TYPES.slice(*caches).values.join(',')
            client.web_client.conversations_list(types: types) do |conversations|
              conversations.channels.each do |channel_data|
                if channel_data.is_mpim?
                  mpim = Models::Mpim.new(channel_data)
                  mpims[mpim.id] = mpims.key?(mpim.id) ? mpims[mpim.id].merge(mpim) : mpim
                elsif channel_data.is_im?
                  im = Models::Im.new(channel_data)
                  ims[im.id] = ims.key?(im.id) ? ims[im.id].merge(im) : im
                elsif channel_data.is_channel? || channel_data.is_group?
                  channel = Models::Channel.new(channel_data)
                  if channel.is_private?
                    private_channels[channel.id] =
                      private_channels.key?(channel.id) ? private_channels[channel.id].merge(channel) : channel
                  else
                    public_channels[channel.id] =
                      public_channels.key?(channel.id) ? public_channels[channel.id].merge(channel) : channel
                  end
                end
              end
            end
          end
          # rubocop:enable Metrics/BlockNesting
        end

        # You closed a DM.
        # @see https://api.slack.com/events/im_close
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/im_close.json
        on :im_close do |data|
          return unless ims&.key?(data.channel)

          ims[data.channel].is_open = false
        end

        # A DM was created.
        # @see https://api.slack.com/events/im_created
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/im_created.json
        on :im_created do |data|
          im = Models::Im.new(data.channel)
          ims[im.id] = im
        end

        # Bulk updates were made to a DM's history.
        # @see https://api.slack.com/events/im_history_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/im_history_changed.json
        # on :im_history_changed do |data|

        # A direct message read marker was updated.
        # @see https://api.slack.com/events/im_marked
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/im_marked.json
        # on :im_marked do |data|

        # You opened a DM.
        # @see https://api.slack.com/events/im_open
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/im_open.json
        on :im_open do |data|
          return unless ims&.key?(data.channel)

          ims[data.channel].is_open = true
        end

        # You manually updated your presence.
        # @see https://api.slack.com/events/manual_presence_change
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/manual_presence_change.json
        on :manual_presence_change do |data|
          self.self.presence = data.presence
        end

        # A user joined a public channel, private channel or MPDM..
        # @see https://api.slack.com/events/member_joined_channel
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/member_joined_channel.json
        on :member_joined_channel do |data|
          channel = public_channels[data.channel] || private_channels[data.channel]
          if channel
            channel.members ||= Set.new
            channel.members << data.user
          end
        end

        # A user left a public or private channel.
        # @see https://api.slack.com/events/member_left_channel
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/member_left_channel.json
        on :member_left_channel do |data|
          channel = public_channels[data.channel] || private_channels[data.channel]
          channel&.members&.delete(data.user)
        end

        # A pin was added to a channel.
        # @see https://api.slack.com/events/pin_added
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/pin_added.json
        # on :pin_added do |data|

        # A pin was removed from a channel.
        # @see https://api.slack.com/events/pin_removed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/pin_removed.json
        # on :pin_removed do |data|

        # You have updated your preferences.
        # @see https://api.slack.com/events/pref_change
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/pref_change.json
        on :pref_change do |data|
          self.self.prefs ||= {}
          self.self.prefs[data.name] = data.value
        end

        # A member's presence changed.
        # @see https://api.slack.com/events/presence_change
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/presence_change.json
        on :presence_change do |data|
          user = users[data.user]
          user.presence = data.presence if user
        end

        # Determine the current presence status for a list of users.
        # @see https://api.slack.com/events/presence_query
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/presence_query.json
        # on :presence_query do |data|

        # Subscribe to presence events for the specified users.
        # @see https://api.slack.com/events/presence_sub
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/presence_sub.json
        # on :presence_sub do |data|

        # A member has added an emoji reaction to an item.
        # @see https://api.slack.com/events/reaction_added
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/reaction_added.json
        # on :reaction_added do |data|

        # A member removed an emoji reaction.
        # @see https://api.slack.com/events/reaction_removed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/reaction_removed.json
        # on :reaction_removed do |data|

        # Experimental.
        # @see https://api.slack.com/events/reconnect_url
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/reconnect_url.json
        # on :reconnect_url do |data|

        # A shared channel invite was sent to a Slack user.
        # @see https://api.slack.com/events/shared_channel_invite_received
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/shared_channel_invite_received.json
        # on :shared_channel_invite_received do |data|

        # A member has saved an item for later or starred an item.
        # @see https://api.slack.com/events/star_added
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/star_added.json
        # on :star_added do |data|

        # A member has removed an item saved for later or starred an item.
        # @see https://api.slack.com/events/star_removed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/star_removed.json
        # on :star_removed do |data|

        # A User Group has been added to the workspace.
        # @see https://api.slack.com/events/subteam_created
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/subteam_created.json
        # on :subteam_created do |data|

        # The membership of an existing User Group has changed.
        # @see https://api.slack.com/events/subteam_members_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/subteam_members_changed.json
        # on :subteam_members_changed do |data|

        # You have been added to a User Group.
        # @see https://api.slack.com/events/subteam_self_added
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/subteam_self_added.json
        # on :subteam_self_added do |data|

        # You have been removed from a User Group.
        # @see https://api.slack.com/events/subteam_self_removed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/subteam_self_removed.json
        # on :subteam_self_removed do |data|

        # An existing User Group has been updated or its members changed.
        # @see https://api.slack.com/events/subteam_updated
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/subteam_updated.json
        # on :subteam_updated do |data|

        # The workspace domain has changed.
        # @see https://api.slack.com/events/team_domain_change
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/team_domain_change.json
        on :team_domain_change do |data|
          team.url = data.url
          team.domain = data.domain
        end

        # A new member has joined.
        # @see https://api.slack.com/events/team_join
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/team_join.json
        on :team_join do |data|
          user = Models::User.new(data.user)
          users[user.id] = user
        end

        # The workspace is being migrated between servers.
        # @see https://api.slack.com/events/team_migration_started
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/team_migration_started.json
        # on :team_migration_started do |data|

        # The account billing plan has changed.
        # @see https://api.slack.com/events/team_plan_change
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/team_plan_change.json
        on :team_plan_change do |data|
          team.plan = data.plan
        end

        # A preference has been updated.
        # @see https://api.slack.com/events/team_pref_change
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/team_pref_change.json
        on :team_pref_change do |data|
          team.prefs ||= {}
          team.prefs[data.name] = data.value
        end

        # The workspace profile fields have been updated.
        # @see https://api.slack.com/events/team_profile_change
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/team_profile_change.json
        # on :team_profile_change do |data|

        # The workspace profile fields have been deleted.
        # @see https://api.slack.com/events/team_profile_delete
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/team_profile_delete.json
        # on :team_profile_delete do |data|

        # The workspace profile fields have been reordered.
        # @see https://api.slack.com/events/team_profile_reorder
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/team_profile_reorder.json
        # on :team_profile_reorder do |data|

        # The workspace name has changed.
        # @see https://api.slack.com/events/team_rename
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/team_rename.json
        on :team_rename do |data|
          team.name = data.name
        end

        # A member's data has changed.
        # @see https://api.slack.com/events/user_change
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/user_change.json
        on :user_change do |data|
          user = Models::User.new(data.user)
          users[user.id] = user
        end

        # A user's huddle status has changed.
        # @see https://api.slack.com/events/user_huddle_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/user_huddle_changed.json
        # on :user_huddle_changed do |data|
        # (handled by :user_change)

        # A user's profile data has changed.
        # @see https://api.slack.com/events/user_profile_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/user_profile_changed.json
        # on :user_profile_changed do |data|
        # (handled by :user_change)

        # A user's status has changed.
        # @see https://api.slack.com/events/user_status_changed
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/user_status_changed.json
        # on :user_status_changed do |data|
        # (handled by :user_change)

        # A channel member is typing a message.
        # @see https://api.slack.com/events/user_typing
        # @see https://github.com/slack-ruby/slack-api-ref/blob/master/events/user_typing.json
        # on :user_typing do |data|
      end
    end
  end
end

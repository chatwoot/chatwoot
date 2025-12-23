# frozen_string_literal: true
module Slack
  module Messages
    module Formatting
      class << self
        #
        # Unescape a message.
        # @see https://api.slack.com/docs/formatting
        #
        def unescape(message)
          CGI.unescapeHTML(message.gsub(/[“”]/, '"')
            .gsub(/[‘’]/, "'")
            .gsub(/<(?<sign>[?@#!]?)(?<dt>.*?)>/) do
              sign = Regexp.last_match[:sign]
              dt = Regexp.last_match[:dt]
              rhs = dt.split('|', 2).last
              case sign
              when '@', '!'
                "@#{rhs}"
              when '#'
                "##{rhs}"
              else
                rhs
              end
            end)
        end

        #
        # Escape a message.
        # @see https://api.slack.com/reference/surfaces/formatting#escaping
        #
        def escape(message)
          message
            .gsub('&', '&amp;')
            .gsub('>', '&gt;')
            .gsub('<', '&lt;')
        end

        #
        # Format a DateTime or Time object as a date and time in a Slack message
        # @see https://api.slack.com/reference/surfaces/formatting#date-formatting
        #
        def date(time, format: '{date_num} {time_secs}', link: nil, text: nil)
          args = [time.to_i, format, link].compact
          "<!date^#{args.join('^')}|#{text || time}>"
        end

        #
        # Embed a link to a Slack channel in a message by channel ID
        # @see https://api.slack.com/reference/surfaces/formatting#linking-channels
        #
        def channel_link(channel_id)
          "<##{channel_id}>"
        end

        #
        # Embed a link to a user in a message by user ID
        # @see https://api.slack.com/reference/surfaces/formatting#mentioning-users
        #
        def user_link(user_id)
          "<@#{user_id}>"
        end

        #
        # Embed a link to a group in a message by group ID
        # @see https://api.slack.com/reference/surfaces/formatting#mentioning-groups
        #
        def group_link(group_id)
          "<!subteam^#{group_id}>"
        end

        #
        # Embed a URL with custom link text in a message
        # @see https://api.slack.com/reference/surfaces/formatting#linking-urls
        #
        def url_link(text, url)
          "<#{url}|#{text}>"
        end

        #
        # Converts text from basic markdown into Slack's mishmash
        # @see https://api.slack.com/reference/surfaces/formatting#basic-formatting
        #
        def markdown(text)
          text
            .gsub(/(?<!\*)\*([^*\n]+)\*(?!\*)/, '_\1_') # italic
            .gsub(/\*\*\*(.*?)\*\*\*/, '*_\1_*') # bold & italic
            .gsub(/\*\*(.*?)\*\*/, '*\1*') # bold
            .gsub(/~~(.*?)~~/, '~\1~') # strikethrough
            .gsub(/\[(.*?)\]\((.*?)\)/, '<\2|\1>') # links
        end
      end
    end
  end
end

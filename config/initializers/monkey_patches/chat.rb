module Slack
  module Web
    module Api
      module Endpoints
        module Chat
          # TODO: Remove this monkey patch when PR for this issue https://github.com/slack-ruby/slack-ruby-client/issues/388 is merged
          def chat_unfurl(options = {})
            if (options[:channel].nil? || options[:ts].nil?) && (options[:unfurl_id].nil? || options[:source].nil?)
              raise ArgumentError, 'Either a combination of :channel and :ts or :unfurl_id and :source is required'
            end

            raise ArgumentError, 'Required arguments :unfurls missing' if options[:unfurls].nil?

            options = options.merge(channel: conversations_id(options)['channel']['id']) if options[:channel]
            post('chat.unfurl', options)
          end
        end
      end
    end
  end
end

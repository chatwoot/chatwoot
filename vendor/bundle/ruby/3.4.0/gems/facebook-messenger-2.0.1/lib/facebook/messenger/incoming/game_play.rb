module Facebook
  module Messenger
    module Incoming
      # The GamePlay class represents an incoming Facebook Messenger
      #   game_play events.
      # @see https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messaging_game_plays
      class GamePlay
        include Facebook::Messenger::Incoming::Common

        def game_play
          @messaging['game_play']
        end

        def payload
          game_play['payload']
        end

        def score
          game_play['score']
        end

        def game
          game_play['game_id']
        end

        def player
          game_play['player_id']
        end

        def context
          {
            context_id: game_play['context_id'],
            context_type: game_play['context_type']
          }
        end
      end
    end
  end
end

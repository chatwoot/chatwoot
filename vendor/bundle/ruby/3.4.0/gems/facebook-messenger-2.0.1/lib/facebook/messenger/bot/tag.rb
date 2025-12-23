module Facebook
  module Messenger
    module Bot
      # Supported tags.
      # Note: A tag is required when sending messages with the
      # message type `MESSAGE_TAG`.
      module Tag
        COMMUNITY_ALERT               = 'COMMUNITY_ALERT'.freeze
        CONFIRMED_EVENT_REMINDER      = 'CONFIRMED_EVENT_REMINDER'.freeze
        NON_PROMOTIONAL_SUBSCRIPTION  = 'NON_PROMOTIONAL_SUBSCRIPTION'.freeze
        PAIRING_UPDATE                = 'PAIRING_UPDATE'.freeze
        APPLICATION_UPDATE            = 'APPLICATION_UPDATE'.freeze
        ACCOUNT_UPDATE                = 'ACCOUNT_UPDATE'.freeze
        PAYMENT_UPDATE                = 'PAYMENT_UPDATE'.freeze
        PERSONAL_FINANCE_UPDATE       = 'PERSONAL_FINANCE_UPDATE'.freeze
        SHIPPING_UPDATE               = 'SHIPPING_UPDATE'.freeze
        RESERVATION_UPDATE            = 'RESERVATION_UPDATE'.freeze
        ISSUE_RESOLUTION              = 'ISSUE_RESOLUTION'.freeze
        APPOINTMENT_UPDATE            = 'APPOINTMENT_UPDATE'.freeze
        GAME_EVENT                    = 'GAME_EVENT'.freeze
        TRANSPORTATION_UPDATE         = 'TRANSPORTATION_UPDATE'.freeze
        FEATURE_FUNCTIONALITY_UPDATE  = 'FEATURE_FUNCTIONALITY_UPDATE'.freeze
        TICKET_UPDATE                 = 'TICKET_UPDATE'.freeze
      end
    end
  end
end

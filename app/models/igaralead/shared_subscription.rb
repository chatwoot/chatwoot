# frozen_string_literal: true

module Igaralead
  # Read-only model mapping to Hub's subscriptions table in the shared DB.
  class SharedSubscription < SharedRecord
    self.table_name = 'subscriptions'

    belongs_to :shared_organization, class_name: 'Igaralead::SharedOrganization',
                                      foreign_key: :organization_id

    scope :active, -> { where(status: 'active') }

    def nexus_user_limit
      nexus_users.to_i
    end

    def nexus_channel_limit
      nexus_channels.to_i
    end
  end
end

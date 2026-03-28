# frozen_string_literal: true

module Igaralead
  # Read-only model mapping to Hub's organizations table in the shared DB.
  class SharedOrganization < SharedRecord
    self.table_name = 'organizations'

    has_many :shared_memberships, class_name: 'Igaralead::SharedMembership',
                                  foreign_key: :organization_id
    has_many :shared_subscriptions, class_name: 'Igaralead::SharedSubscription',
                                    foreign_key: :organization_id
  end
end

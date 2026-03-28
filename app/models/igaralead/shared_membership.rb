# frozen_string_literal: true

module Igaralead
  # Read-only model mapping to Hub's org_members table in the shared DB.
  class SharedMembership < SharedRecord
    self.table_name = 'org_members'

    belongs_to :shared_organization, class_name: 'Igaralead::SharedOrganization',
                                      foreign_key: :organization_id
    belongs_to :shared_user, class_name: 'Igaralead::SharedUser',
                              foreign_key: :user_id
  end
end

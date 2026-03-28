# frozen_string_literal: true

module Igaralead
  # Read-only model mapping to Hub's users table in the shared DB.
  class SharedUser < SharedRecord
    self.table_name = 'users'

    has_many :shared_memberships, class_name: 'Igaralead::SharedMembership',
                                  foreign_key: :user_id
  end
end

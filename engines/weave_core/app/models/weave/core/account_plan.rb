module Weave
  module Core
    class AccountPlan < ApplicationRecord
      self.table_name = 'weave_core_account_plans'

      belongs_to :account, class_name: '::Account'

      PLAN_KEYS = %w[basic pro premium app custom].freeze
      STATUSES = %w[active trial suspended].freeze

      validates :plan_key, inclusion: { in: PLAN_KEYS }
      validates :status, inclusion: { in: STATUSES }
      validates :account_id, presence: true, uniqueness: true
    end
  end
end


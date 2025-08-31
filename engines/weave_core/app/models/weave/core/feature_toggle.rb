module Weave
  module Core
    class FeatureToggle < ApplicationRecord
      self.table_name = 'weave_core_feature_toggles'

      belongs_to :account, class_name: '::Account'

      validates :feature_key, presence: true
      validates :account_id, presence: true
      validates :feature_key, uniqueness: { scope: :account_id }
    end
  end
end

